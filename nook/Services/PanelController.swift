import AppKit
import SwiftUI
import Observation

@MainActor
@Observable
final class PanelController {
    private var panel: FloatingPanel?
    private let notchDetector: NotchDetector
    private let configManager: ConfigurationManager
    private var hostingViewInstalled = false

    /// Drives the SwiftUI transition -- toggled by show/hide.
    var showContent = false

    private(set) var isVisible = false

    init(notchDetector: NotchDetector, configManager: ConfigurationManager) {
        self.notchDetector = notchDetector
        self.configManager = configManager
    }

    var panelFrame: NSRect {
        panel?.frame ?? .zero
    }

    func showPanel() {
        guard !isVisible else { return }
        isVisible = true

        let config = configManager.configuration
        let panelWidth = config.panelWidth
        let itemCount = config.items.count
        let columns = config.columns
        let rows = ceil(Double(itemCount) / Double(columns))
        let rowHeight: Double = 96
        let panelHeight = rows * rowHeight + 28

        let anchor = notchDetector.panelAnchor
        let panelRect = NSRect(
            x: anchor.x - panelWidth / 2,
            y: anchor.y - panelHeight,
            width: panelWidth,
            height: panelHeight
        )

        ensurePanel(config: config, panelWidth: panelWidth, panelHeight: panelHeight)

        guard let panel else { return }

        panel.setFrame(panelRect, display: true)
        panel.alphaValue = 1
        panel.orderFrontRegardless()
        panel.makeKey()

        // Trigger the reveal transition
        withAnimation(.spring(duration: 0.4, bounce: 0.15)) {
            showContent = true
        }
    }

    func hidePanel() {
        guard isVisible else { return }
        isVisible = false

        withAnimation(.easeOut(duration: 0.25)) {
            showContent = false
        } completion: { [weak self] in
            self?.panel?.orderOut(nil)
        }
    }

    private func ensurePanel(config: NookConfiguration, panelWidth: Double, panelHeight: Double) {
        if panel == nil {
            panel = FloatingPanel(
                contentRect: NSRect(origin: .zero, size: CGSize(width: panelWidth, height: panelHeight))
            )
        }

        guard !hostingViewInstalled, let panel else { return }

        let content = PanelHostView(
            panelController: self,
            configManager: configManager
        )
        .frame(width: panelWidth, height: panelHeight)
        .ignoresSafeArea()

        let hostingView = NSHostingView(rootView: content)
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView
        hostingViewInstalled = true
    }
}

/// A long-lived SwiftUI view hosted in the panel that reacts to
/// PanelController.showContent to trigger the liquid drip transition.
struct PanelHostView: View {
    let panelController: PanelController
    let configManager: ConfigurationManager

    var body: some View {
        ZStack {
            if panelController.showContent {
                NookPanelContent(
                    configuration: configManager.configuration,
                    onItemTapped: { item in
                        ShortcutLauncher.launch(item)
                        // Don't dismiss the panel for task-mode scripts
                        if case .shellScript(_, _, let runAsTask) = item.type, runAsTask == true {
                            return
                        }
                        panelController.hidePanel()
                    }
                )
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.95, anchor: .top)),
                        removal: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.95, anchor: .top))
                    )
                )
            }
        }
    }
}
