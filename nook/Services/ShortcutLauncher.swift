import AppKit

@MainActor
enum ShortcutLauncher {
    static func launch(_ item: ShortcutItem) {
        switch item.type {
        case .app(let bundleIdentifier):
            launchApp(bundleIdentifier: bundleIdentifier)
        case .url(let urlString):
            openURL(urlString)
        case .file(let path):
            openFile(path)
        case .shellScript(_, _, let runAsTask) where runAsTask == true:
            TaskManager.shared.toggleTask(for: item)
        case .shellScript(let path, let arguments, _):
            Task { await runShellScript(path: path, arguments: arguments) }
        case .shortcutsApp(let shortcutName):
            Task { await runShortcut(name: shortcutName) }
        case .terminal(let command, let directory, let app):
            // Wait for all modifier keys to be released before sending keystrokes,
            // otherwise held modifiers (from the global shortcut) interfere with AppleScript.
            Task {
                await waitForModifierRelease()
                openTerminal(command: command, directory: directory, app: app)
            }
        }
    }

    private static func launchApp(bundleIdentifier: String) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            NSLog("Nook: Could not find app with bundle ID: \(bundleIdentifier)")
            return
        }
        NSWorkspace.shared.openApplication(at: url, configuration: .init())
    }

    private static func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            NSLog("Nook: Invalid URL: \(urlString)")
            return
        }
        NSWorkspace.shared.open(url)
    }

    /// Brief delay to let modifier keys be released before sending keystrokes.
    @concurrent
    private nonisolated static func waitForModifierRelease() async {
        try? await Task.sleep(for: .milliseconds(200))
    }

    private static func openFile(_ path: String) {
        let expanded = NSString(string: path).expandingTildeInPath
        let url = URL(fileURLWithPath: expanded)
        NSWorkspace.shared.open(url)
    }

    @concurrent
    private nonisolated static func runShellScript(path: String, arguments: [String]?) async {
        let expanded = NSString(string: path).expandingTildeInPath

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        if let arguments {
            process.arguments = ["-c", "\(expanded) \(arguments.joined(separator: " "))"]
        } else {
            process.arguments = ["-c", expanded]
        }
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            NSLog("Nook: Failed to run script: \(error.localizedDescription)")
        }
    }

    private static func openTerminal(command: String, directory: String?, app: String?) {
        let terminalApp = app ?? "Terminal"
        let expandedDir = directory.map { NSString(string: $0).expandingTildeInPath }

        // Build the full command with optional cd prefix
        let fullCommand: String
        if let expandedDir {
            fullCommand = "cd \(shellQuote(expandedDir)) && \(command)"
        } else {
            fullCommand = command
        }

        switch terminalApp.lowercased() {
        case "terminal", "terminal.app":
            runAppleScript("""
            tell application "Terminal"
                activate
                do script "\(escapeForAppleScript(fullCommand))"
            end tell
            """)

        case "iterm", "iterm2", "iterm.app", "iterm2.app":
            runAppleScript("""
            tell application "iTerm"
                activate
                create window with default profile command "\(escapeForAppleScript(fullCommand))"
            end tell
            """)

        case "ghostty", "ghostty.app":
            // Open a new tab in Ghostty and type the command.
            // Requires Accessibility permission in System Settings.
            runAppleScript("""
            tell application "Ghostty"
                activate
            end tell
            tell application "System Events" to tell process "Ghostty"
                keystroke "t" using command down
            end tell
            delay 0.3
            tell application "System Events" to tell process "Ghostty"
                keystroke "\(escapeForAppleScript(fullCommand))"
                keystroke return
            end tell
            """)

        case "warp", "warp.app":
            // Warp doesn't have a CLI -e flag; use AppleScript to activate then type
            runAppleScript("""
            tell application "Warp"
                activate
            end tell
            """)

        case "kitty", "kitty.app":
            Task { await launchWithCLI(executable: "/Applications/kitty.app/Contents/MacOS/kitty", args: ["/bin/zsh", "-c", fullCommand]) }

        case "alacritty", "alacritty.app":
            Task { await launchWithCLI(executable: "/Applications/Alacritty.app/Contents/MacOS/alacritty", args: ["-e", "/bin/zsh", "-c", fullCommand]) }

        default:
            // Generic fallback: try `open -a AppName` and use AppleScript to type the command
            Task { await launchWithOpen(appName: terminalApp, command: fullCommand) }
        }
    }

    private static func runAppleScript(_ source: String) {
        guard let script = NSAppleScript(source: source) else {
            NSLog("Nook: Failed to create AppleScript")
            return
        }
        var error: NSDictionary?
        script.executeAndReturnError(&error)
        if let error {
            NSLog("Nook: AppleScript error: %@", error.description)
        }
    }

    private static func escapeForAppleScript(_ string: String) -> String {
        string.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    private static func shellQuote(_ string: String) -> String {
        "'" + string.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    /// Launch a terminal by invoking its binary directly with arguments.
    @concurrent
    private nonisolated static func launchWithCLI(executable: String, args: [String]) async {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = args
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            NSLog("Nook: Failed to launch terminal at \(executable): \(error.localizedDescription)")
        }
    }

    /// Fallback: open the app with `open -a`, then wait briefly and use
    /// AppleScript System Events to type the command + press Enter.
    @concurrent
    private nonisolated static func launchWithOpen(appName: String, command: String) async {
        let open = Process()
        open.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        open.arguments = ["-a", appName]
        try? open.run()
        open.waitUntilExit()

        // Give the terminal time to open and focus
        try? await Task.sleep(for: .milliseconds(800))

        let escaped = command.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
        tell application "System Events"
            keystroke "\(escaped)"
            keystroke return
        end tell
        """
        await MainActor.run {
            runAppleScript(script)
        }
    }

    @concurrent
    private nonisolated static func runShortcut(name: String) async {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["run", name]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            NSLog("Nook: Failed to run shortcut '\(name)': \(error.localizedDescription)")
        }
    }
}
