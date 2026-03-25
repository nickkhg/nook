import AppKit

@MainActor
final class MouseTracker {
    var onEnterTriggerZone: (() -> Void)?
    var onExitPanel: (() -> Void)?

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var dismissTimer: Timer?
    private var isInsidePanel = false

    private let notchDetector: NotchDetector
    private var panelFrame: NSRect = .zero
    private let graceMargin: Double = 20
    private let dismissDelay: TimeInterval = 0.3

    init(notchDetector: NotchDetector) {
        self.notchDetector = notchDetector
    }

    func start() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.handleMouseMoved()
            }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            MainActor.assumeIsolated {
                self?.handleMouseMoved()
            }
            return event
        }
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        globalMonitor = nil
        localMonitor = nil
        dismissTimer?.invalidate()
    }

    func updatePanelFrame(_ frame: NSRect) {
        self.panelFrame = frame
    }

    private func handleMouseMoved() {
        let mouseLocation = NSEvent.mouseLocation
        let triggerZone = notchDetector.triggerZone

        // Expand panel frame with grace margin for hit testing
        let expandedPanelFrame = panelFrame.insetBy(dx: -graceMargin, dy: -graceMargin)

        let inTriggerZone = triggerZone.contains(mouseLocation)
        let inPanelArea = !panelFrame.isEmpty && expandedPanelFrame.contains(mouseLocation)

        if inTriggerZone && !isInsidePanel {
            // Entered the trigger zone
            dismissTimer?.invalidate()
            dismissTimer = nil
            isInsidePanel = true
            onEnterTriggerZone?()
        } else if isInsidePanel && !inTriggerZone && !inPanelArea {
            // Left both the trigger zone and the panel area
            startDismissTimer()
        } else if isInsidePanel && (inTriggerZone || inPanelArea) {
            // Still inside, cancel any pending dismiss
            dismissTimer?.invalidate()
            dismissTimer = nil
        }
    }

    private func startDismissTimer() {
        guard dismissTimer == nil else { return }
        dismissTimer = Timer.scheduledTimer(withTimeInterval: dismissDelay, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.isInsidePanel = false
                self?.onExitPanel?()
                self?.dismissTimer = nil
            }
        }
    }
}
