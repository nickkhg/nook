import AppKit

extension NSScreen {
    /// Whether this screen has a notch (camera housing).
    var hasNotch: Bool {
        safeAreaInsets.top > 0
    }

    /// The rectangle of the notch area in screen coordinates (origin bottom-left).
    /// Returns nil on non-notched displays.
    var notchRect: NSRect? {
        guard hasNotch else { return nil }

        let screenFrame = frame
        let leftArea = auxiliaryTopLeftArea
        let rightArea = auxiliaryTopRightArea

        // The notch is the gap between the left and right auxiliary areas
        let notchLeft = leftArea?.maxX ?? screenFrame.minX
        let notchRight = rightArea?.minX ?? screenFrame.maxX
        let notchWidth = notchRight - notchLeft
        let notchHeight = safeAreaInsets.top

        return NSRect(
            x: notchLeft,
            y: screenFrame.maxY - notchHeight,
            width: notchWidth,
            height: notchHeight
        )
    }

    /// The trigger zone for mouse detection -- either the notch area or a
    /// virtual zone at top-center for non-notched displays.
    /// Extends 1pt past the screen top edge so NSRect.contains() catches
    /// the cursor when it's pinned to the very top pixel (half-open interval).
    func triggerZone(height: Double = 5) -> NSRect {
        if let notch = notchRect {
            // Extend 1pt above the screen edge to catch the top-most cursor position
            return NSRect(
                x: notch.minX,
                y: notch.minY,
                width: notch.width,
                height: notch.height + 1
            )
        }

        // Fallback for non-notched displays: centered zone at top of screen
        let zoneWidth: Double = 200
        let screenFrame = frame
        return NSRect(
            x: screenFrame.midX - zoneWidth / 2,
            y: screenFrame.maxY - height,
            width: zoneWidth,
            height: height + 1
        )
    }

    /// The point where the panel should be anchored (top-center, below notch/menu bar).
    var panelAnchorPoint: NSPoint {
        let screenFrame = frame
        let topInset = safeAreaInsets.top > 0 ? safeAreaInsets.top : 24  // 24pt for standard menu bar
        return NSPoint(
            x: screenFrame.midX,
            y: screenFrame.maxY - topInset
        )
    }
}
