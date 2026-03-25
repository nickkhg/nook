import Foundation

struct ShortcutItem: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var label: String
    var type: ShortcutType
    var iconOverride: String?

    enum ShortcutType: Codable, Hashable {
        case app(bundleIdentifier: String)
        case url(urlString: String)
        case file(path: String)
        case shellScript(path: String, arguments: [String]?)
        case shortcutsApp(shortcutName: String)

        private enum CodingKeys: String, CodingKey {
            case kind
            case bundleIdentifier
            case urlString
            case path
            case arguments
            case shortcutName
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let kind = try container.decode(String.self, forKey: .kind)

            switch kind {
            case "app":
                let id = try container.decode(String.self, forKey: .bundleIdentifier)
                self = .app(bundleIdentifier: id)
            case "url":
                let url = try container.decode(String.self, forKey: .urlString)
                self = .url(urlString: url)
            case "file":
                let path = try container.decode(String.self, forKey: .path)
                self = .file(path: path)
            case "shellScript":
                let path = try container.decode(String.self, forKey: .path)
                let args = try container.decodeIfPresent([String].self, forKey: .arguments)
                self = .shellScript(path: path, arguments: args)
            case "shortcutsApp":
                let name = try container.decode(String.self, forKey: .shortcutName)
                self = .shortcutsApp(shortcutName: name)
            default:
                throw DecodingError.dataCorruptedError(
                    forKey: .kind, in: container,
                    debugDescription: "Unknown shortcut kind: \(kind)"
                )
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .app(let bundleIdentifier):
                try container.encode("app", forKey: .kind)
                try container.encode(bundleIdentifier, forKey: .bundleIdentifier)
            case .url(let urlString):
                try container.encode("url", forKey: .kind)
                try container.encode(urlString, forKey: .urlString)
            case .file(let path):
                try container.encode("file", forKey: .kind)
                try container.encode(path, forKey: .path)
            case .shellScript(let path, let arguments):
                try container.encode("shellScript", forKey: .kind)
                try container.encode(path, forKey: .path)
                try container.encodeIfPresent(arguments, forKey: .arguments)
            case .shortcutsApp(let shortcutName):
                try container.encode("shortcutsApp", forKey: .kind)
                try container.encode(shortcutName, forKey: .shortcutName)
            }
        }
    }
}
