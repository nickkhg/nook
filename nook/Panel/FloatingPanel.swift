import SwiftUI

/// An NSPanel subclass that uses .titled style mask (with hidden chrome)
/// so the system compositor supports glass effects and materials.
@MainActor
class FloatingPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Floating panel behavior
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        animationBehavior = .utilityWindow
        hidesOnDeactivate = false
        isMovableByWindowBackground = false

        // Transparent window -- SwiftUI handles its own background
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
