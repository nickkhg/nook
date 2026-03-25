import AppKit
import Observation

@MainActor
@Observable
final class NotchDetector {
    var triggerZone: NSRect = .zero
    var panelAnchor: NSPoint = .zero
    var hasNotch: Bool = false

    private var triggerHeight: Double

    init(triggerHeight: Double = 5) {
        self.triggerHeight = triggerHeight
        update()
        observeScreenChanges()
    }

    func update() {
        guard let screen = NSScreen.main else { return }
        hasNotch = screen.hasNotch
        triggerZone = screen.triggerZone(height: triggerHeight)
        panelAnchor = screen.panelAnchorPoint
    }

    func updateTriggerHeight(_ height: Double) {
        triggerHeight = height
        update()
    }

    private func observeScreenChanges() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.update()
            }
        }
    }
}
