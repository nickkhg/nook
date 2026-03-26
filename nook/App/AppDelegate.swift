import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let panelController: PanelController

    private let notchDetector: NotchDetector
    private var mouseTracker: MouseTracker?
    private let hotkeyMonitor = HotkeyMonitor()

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
        // Show onboarding window if not completed yet
        if !UserDefaults.standard.bool(forKey: "onboardingCompleted") {
            showOnboardingWindow()
        }

        let tracker = MouseTracker(notchDetector: notchDetector)

        tracker.onEnterTriggerZone = { [weak self] in
            self?.panelController.showPanel()
        }

        tracker.onExitPanel = { [weak self] in
            self?.panelController.hidePanel()
        }

        tracker.start()
        mouseTracker = tracker

        // Set up global hotkeys from config
        let config = ConfigurationManager.shared.configuration
        hotkeyMonitor.updateBindings(from: config.items)
        hotkeyMonitor.isPanelVisible = { [weak self] in
            self?.panelController.isVisible ?? false
        }
        hotkeyMonitor.onPanelItemLaunched = { [weak self] item in
            if case .shellScript(_, _, let runAsTask) = item.type, runAsTask == true {
                return
            }
            self?.panelController.hidePanel()
        }
        hotkeyMonitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        mouseTracker?.stop()
    }

    func showOnboardingWindow() {
        // If already open, just bring it to front
        if let existing = onboardingWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let controller = NSHostingController(
            rootView: OnboardingView {
                self.onboardingWindow?.close()
            }
        )

        let window = NSWindow(contentViewController: controller)
        window.title = "Nook Setup"
        window.styleMask = [.titled, .closable]
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        onboardingWindow = window
    }

    private var onboardingWindow: NSWindow?
}
