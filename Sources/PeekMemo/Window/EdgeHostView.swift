import AppKit
import PeekMemoCore

/// Transparent event view. Distinguishes click vs drag using `LayoutMetrics.dragThreshold`.
final class EdgeHostView: NSView {
    var onDragBegan: (() -> Void)?
    var onDrag: ((CGPoint) -> Void)?
    var onDragEnded: ((CGPoint) -> Void)?
    var onClick: (() -> Void)?
    var onPointerEntered: (() -> Void)?
    var onPointerExited: (() -> Void)?
    var onPointerMoved: ((CGPoint) -> Void)?

    /// When set, only this rect (view coordinates) starts a drag or a pin click.
    var dragHandleRect: CGRect?

    private var dragOrigin: CGPoint?
    private var isDragging = false
    private var handlePress = false

    override var isFlipped: Bool { false }
    override var mouseDownCanMoveWindow: Bool { false }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        bounds.contains(point) ? self : nil
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas {
            removeTrackingArea(area)
        }
        let options: NSTrackingArea.Options = [
            .mouseEnteredAndExited,
            .mouseMoved,
            .activeAlways,
            .inVisibleRect,
        ]
        addTrackingArea(NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil))
    }

    override func mouseEntered(with event: NSEvent) {
        onPointerEntered?()
    }

    override func mouseExited(with event: NSEvent) {
        onPointerExited?()
    }

    override func mouseMoved(with event: NSEvent) {
        onPointerMoved?(NSEvent.mouseLocation)
    }

    override func mouseDown(with event: NSEvent) {
        let local = convert(event.locationInWindow, from: nil)
        if let dragHandleRect, !dragHandleRect.contains(local) {
            dragOrigin = nil
            handlePress = false
            isDragging = false
            return
        }
        handlePress = true
        dragOrigin = NSEvent.mouseLocation
        isDragging = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard handlePress, let origin = dragOrigin else { return }
        let location = NSEvent.mouseLocation
        if !isDragging {
            let dx = location.x - origin.x
            let dy = location.y - origin.y
            if hypot(dx, dy) >= LayoutMetrics.dragThreshold {
                isDragging = true
                onDragBegan?()
            }
        }
        if isDragging {
            onDrag?(location)
        }
    }

    override func mouseUp(with event: NSEvent) {
        let location = NSEvent.mouseLocation
        if isDragging {
            onDragEnded?(location)
        } else if handlePress {
            onClick?()
        }
        dragOrigin = nil
        isDragging = false
        handlePress = false
    }
}
