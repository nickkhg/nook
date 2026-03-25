import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var notchDetector: NotchDetector!
    private var mouseTracker: MouseTracker!
    private var panelController: PanelController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let configManager = ConfigurationManager.shared

        notchDetector = NotchDetector(
            triggerHeight: configManager.configuration.triggerHeight
        )

        panelController = PanelController(
            notchDetector: notchDetector,
            configManager: configManager
        )

        mouseTracker = MouseTracker(notchDetector: notchDetector)

        mouseTracker.onEnterTriggerZone = { [weak self] in
            guard let self else { return }
            panelController.showPanel()
            mouseTracker.updatePanelFrame(panelController.panelFrame)
        }

        mouseTracker.onExitPanel = { [weak self] in
            self?.panelController.hidePanel()
        }

        mouseTracker.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        mouseTracker?.stop()
    }
}
