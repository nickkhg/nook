import Foundation

struct NookConfiguration: Codable, Sendable {
    var schema: String = "https://github.com/nickkhg/nook/raw/main/nook-config.schema.json"
    var items: [ShortcutItem]
    var columns: Int
    var triggerHeight: Double
    var panelWidth: Double

    enum CodingKeys: String, CodingKey {
        case schema = "$schema"
        case items, columns, triggerHeight, panelWidth
    }

    static let `default` = NookConfiguration(
        items: [
            ShortcutItem(
                id: UUID(),
                label: "Safari",
                type: .app(bundleIdentifier: "com.apple.Safari")
            ),
            ShortcutItem(
                id: UUID(),
                label: "Finder",
                type: .app(bundleIdentifier: "com.apple.finder")
            ),
            ShortcutItem(
                id: UUID(),
                label: "Terminal",
                type: .app(bundleIdentifier: "com.apple.Terminal")
            ),
            ShortcutItem(
                id: UUID(),
                label: "System Settings",
                type: .app(bundleIdentifier: "com.apple.systempreferences")
            ),
            ShortcutItem(
                id: UUID(),
                label: "GitHub",
                type: .url(urlString: "https://github.com")
            ),
            ShortcutItem(
                id: UUID(),
                label: "Downloads",
                type: .file(path: "~/Downloads")
            ),
        ],
        columns: 4,
        triggerHeight: 5,
        panelWidth: 340
    )
}
