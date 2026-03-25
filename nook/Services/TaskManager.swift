import Foundation
import Observation

/// Tracks running shell script processes by ShortcutItem ID.
/// Allows starting, monitoring, and killing background tasks.
@MainActor
@Observable
final class TaskManager {
    static let shared = TaskManager()

    /// Item IDs that currently have a running process.
    private(set) var runningTasks: [UUID: Process] = [:]

    private init() {}

    func isRunning(_ itemID: UUID) -> Bool {
        guard let process = runningTasks[itemID] else { return false }
        return process.isRunning
    }

    /// Start a shell script as a tracked background task.
    func startTask(for item: ShortcutItem) {
        guard case .shellScript(let path, let arguments, _) = item.type else { return }
        guard !isRunning(item.id) else { return }

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

        // Clean up when the process terminates naturally
        let itemID = item.id
        process.terminationHandler = { [weak self] _ in
            Task { @MainActor in
                self?.runningTasks.removeValue(forKey: itemID)
            }
        }

        do {
            try process.run()
            runningTasks[itemID] = process
        } catch {
            NSLog("Nook: Failed to start task: \(error.localizedDescription)")
        }
    }

    /// Kill a running task.
    func killTask(for itemID: UUID) {
        guard let process = runningTasks[itemID], process.isRunning else {
            runningTasks.removeValue(forKey: itemID)
            return
        }
        process.terminate()
        runningTasks.removeValue(forKey: itemID)
    }

    /// Toggle a task: start if not running, kill if running.
    func toggleTask(for item: ShortcutItem) {
        if isRunning(item.id) {
            killTask(for: item.id)
        } else {
            startTask(for: item)
        }
    }
}
