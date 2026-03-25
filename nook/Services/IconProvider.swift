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
        }
    }

    private static func appIcon(for bundleIdentifier: String) -> NSImage {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            return NSWorkspace.shared.icon(forFile: appURL.path)
        }
        return NSImage(named: NSImage.applicationIconName)!
    }
}
