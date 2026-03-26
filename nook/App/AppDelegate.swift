import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let panelController: PanelController

    private let notchDetector: NotchDetector
    private var mouseTracker: MouseTracker?

    override init() {
        let configManager = ConfigurationManager.shared

        notchDetector = NotchDetector(
            triggerHeight: configManager.configuration.triggerHeight
        )

        panelController = PanelController(
            notchDetector: notchDetector,
            configManager: configManager
        )

        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let tracker = MouseTracker(notchDetector: notchDetector)

        tracker.onEnterTriggerZone = { [weak self] in
            self?.panelController.showPanel()
        }

        tracker.onExitPanel = { [weak self] in
            self?.panelController.hidePanel()
        }

        tracker.start()
        mouseTracker = tracker
    }

    func applicationWillTerminate(_ notification: Notification) {
        mouseTracker?.stop()
    }

}
