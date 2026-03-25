import AppKit
import SwiftUI

@MainActor
final class PanelController {
    private var panel: FloatingPanel?
    private let notchDetector: NotchDetector
    private let configManager: ConfigurationManager

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

        let content = NookPanelContent(
            configuration: config,
            onItemTapped: { [weak self] item in
                ShortcutLauncher.launch(item)
                self?.hidePanel()
            }
        )
        .frame(width: panelWidth, height: panelHeight)
        .ignoresSafeArea()

        if panel == nil {
            panel = FloatingPanel(
                contentRect: NSRect(origin: .zero, size: panelRect.size)
            )
        }

        guard let panel else { return }

        let hostingView = NSHostingView(rootView: content)
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView

        panel.setFrame(panelRect, display: true)
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        panel.makeKey()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }
    }

    func hidePanel() {
        guard isVisible, let panel else { return }
        isVisible = false

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        }, completionHandler: {
            MainActor.assumeIsolated {
                panel.orderOut(nil)
            }
        })
    }
}
