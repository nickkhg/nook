import Foundation
import Observation

@MainActor
@Observable
final class ConfigurationManager {
    var configuration: NookConfiguration

    private let configURL: URL
    private var fileWatchSource: DispatchSourceFileSystemObject?
    private var isSaving = false

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
            // Save back to persist any auto-generated UUIDs (only if needed)
            saveIfNeeded(originalData: data)
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
        isSaving = true
        try? data.write(to: configURL, options: .atomic)
        // Reset after a short delay to ignore the file watcher event we just caused
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isSaving = false
        }
    }

    func reload() {
        guard !isSaving else { return }
        guard let data = try? Data(contentsOf: configURL),
              let config = try? JSONDecoder().decode(NookConfiguration.self, from: data) else { return }
        self.configuration = config
    }

    var configFilePath: String {
        configURL.path
    }

    /// Only saves if the config has new auto-generated data (e.g. UUIDs).
    /// Compares the decoded-then-re-encoded config against original to detect changes.
    private func saveIfNeeded(originalData: Data) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let newData = try? encoder.encode(configuration) else { return }
        // Only save if the semantic content changed (not just formatting)
        let originalConfig = try? JSONDecoder().decode(NookConfiguration.self, from: originalData)
        let newConfig = try? JSONDecoder().decode(NookConfiguration.self, from: newData)
        guard let originalConfig, let newConfig else { return }

        // Compare item count and IDs to detect auto-generated UUIDs
        let originalIDs = Set(originalConfig.items.map(\.id))
        let newIDs = Set(newConfig.items.map(\.id))
        if originalIDs != newIDs {
            save()
        }
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
