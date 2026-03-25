import Foundation
import Observation

@MainActor
@Observable
final class ConfigurationManager {
    var configuration: NookConfiguration

    private let configURL: URL
    private var fileWatchSource: DispatchSourceFileSystemObject?

    static let shared = ConfigurationManager()

    private init() {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first else {
            fatalError("Application Support directory not found")
        }
        let nookDir = appSupport.appending(path: "nook", directoryHint: .isDirectory)
        self.configURL = nookDir.appending(path: "config.json")

        // Load or create default config
        if let data = try? Data(contentsOf: configURL),
           let config = try? JSONDecoder().decode(NookConfiguration.self, from: data) {
            self.configuration = config
        } else {
            self.configuration = .default
            try? FileManager.default.createDirectory(at: nookDir, withIntermediateDirectories: true)
            save()
        }

        startWatching()
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(configuration) else { return }
        try? data.write(to: configURL, options: .atomic)
    }

    func reload() {
        guard let data = try? Data(contentsOf: configURL),
              let config = try? JSONDecoder().decode(NookConfiguration.self, from: data) else { return }
        self.configuration = config
    }

    var configFilePath: String {
        configURL.path
    }

    private func startWatching() {
        let fd = open(configURL.path, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: .write,
            queue: .main
        )
        source.setEventHandler { [weak self] in
            MainActor.assumeIsolated {
                self?.reload()
            }
        }
        source.setCancelHandler {
            close(fd)
        }
        source.resume()
        self.fileWatchSource = source
    }
}
