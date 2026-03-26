import AppKit

@MainActor
enum IconProvider {
    static func icon(for item: ShortcutItem) -> NSImage {
        // Check for SF Symbol override first
        if let override = item.iconOverride,
           let image = NSImage(systemSymbolName: override, accessibilityDescription: item.label) {
            return image
        }

        switch item.type {
        case .app(let bundleIdentifier):
            return appIcon(for: bundleIdentifier)
        case .url:
            return NSImage(systemSymbolName: "globe", accessibilityDescription: "URL")
                ?? NSImage(named: NSImage.networkName)!
        case .file(let path):
            let expanded = NSString(string: path).expandingTildeInPath
            return NSWorkspace.shared.icon(forFile: expanded)
        case .shellScript:
            return NSImage(systemSymbolName: "terminal", accessibilityDescription: "Script")
                ?? NSImage(named: NSImage.applicationIconName)!
        case .shortcutsApp:
            return NSImage(systemSymbolName: "command.square", accessibilityDescription: "Shortcut")
                ?? NSImage(named: NSImage.applicationIconName)!
        case .terminal(_, _, let app):
            // Try to show the actual terminal app's icon
            if let app, let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: terminalBundleID(for: app)) {
                return NSWorkspace.shared.icon(forFile: appURL.path)
            }
            return NSImage(systemSymbolName: "apple.terminal", accessibilityDescription: "Terminal")
                ?? NSImage(systemSymbolName: "terminal", accessibilityDescription: "Terminal")
                ?? NSImage(named: NSImage.applicationIconName)!
        }
    }

    private static func terminalBundleID(for appName: String) -> String {
        switch appName.lowercased() {
        case "terminal", "terminal.app": return "com.apple.Terminal"
        case "iterm", "iterm2", "iterm.app", "iterm2.app": return "com.googlecode.iterm2"
        case "warp", "warp.app": return "dev.warp.Warp-Stable"
        case "ghostty", "ghostty.app": return "com.mitchellh.ghostty"
        case "kitty", "kitty.app": return "net.kovidgoyal.kitty"
        case "alacritty", "alacritty.app": return "org.alacritty"
        default: return appName
        }
    }

    private static func appIcon(for bundleIdentifier: String) -> NSImage {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            return NSWorkspace.shared.icon(forFile: appURL.path)
        }
        return NSImage(named: NSImage.applicationIconName)!
    }
}
