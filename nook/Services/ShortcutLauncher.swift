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
            openTerminal(command: command, directory: directory, app: app)
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

        case "warp", "warp.app":
            runAppleScript("""
            tell application "Warp"
                activate
            end tell
            """)
            // Warp doesn't support AppleScript commands well; use open + CLI
            Task { await launchCLITerminal(bundleID: "dev.warp.Warp-Stable", command: fullCommand) }

        default:
            // Generic fallback: open the app, then use `open -a` with a temporary script
            Task { await launchGenericTerminal(appName: terminalApp, command: fullCommand) }
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
            NSLog("Nook: AppleScript error: \(error)")
        }
    }

    private static func escapeForAppleScript(_ string: String) -> String {
        string.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    private static func shellQuote(_ string: String) -> String {
        "'" + string.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    @concurrent
    private nonisolated static func launchCLITerminal(bundleID: String, command: String) async {
        // Write command to a temp script and open it with the terminal
        let tempScript = NSTemporaryDirectory() + "nook-cmd-\(UUID().uuidString).sh"
        let scriptContent = "#!/bin/zsh\n\(command)\n"
        try? scriptContent.write(toFile: tempScript, atomically: true, encoding: .utf8)
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tempScript)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-b", bundleID, tempScript]
        try? process.run()
        process.waitUntilExit()

        // Clean up after a delay
        try? await Task.sleep(for: .seconds(2))
        try? FileManager.default.removeItem(atPath: tempScript)
    }

    @concurrent
    private nonisolated static func launchGenericTerminal(appName: String, command: String) async {
        // Open the terminal app and execute via a temp script
        let tempScript = NSTemporaryDirectory() + "nook-cmd-\(UUID().uuidString).sh"
        let scriptContent = "#!/bin/zsh\n\(command)\n"
        try? scriptContent.write(toFile: tempScript, atomically: true, encoding: .utf8)
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tempScript)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", appName, tempScript]
        try? process.run()
        process.waitUntilExit()

        try? await Task.sleep(for: .seconds(2))
        try? FileManager.default.removeItem(atPath: tempScript)
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
