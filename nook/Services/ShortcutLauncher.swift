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
