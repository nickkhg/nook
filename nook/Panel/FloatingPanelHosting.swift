import AppKit
import SwiftUI

@MainActor
final class FloatingPanelHosting<Content: View> {
    let panel: FloatingPanel

    init(contentRect: NSRect, @ViewBuilder content: () -> Content) {
        self.panel = FloatingPanel(contentRect: contentRect)
        let hostingView = NSHostingView(rootView: content())
        hostingView.frame = contentRect
        panel.contentView = hostingView
    }

    func updateContent<V: View>(@ViewBuilder _ content: () -> V) {
        let hostingView = NSHostingView(rootView: content())
        hostingView.frame = panel.contentView?.bounds ?? .zero
        panel.contentView = hostingView
    }
}
