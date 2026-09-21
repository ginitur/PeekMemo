import AppKit
import PeekMemoCore

/// Transparent event view. Distinguishes click vs drag using `LayoutMetrics.dragThreshold`.
final class EdgeHostView: NSView {
    var onDrag: ((CGPoint) -> Void)?
    var onDragEnded: ((CGPoint) -> Void)?
    var onClick: (() -> Void)?

    private var dragOrigin: CGPoint?
    private var isDragging = false

    override var isFlipped: Bool { false }
    override var mouseDownCanMoveWindow: Bool { false }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        bounds.contains(point) ? self : nil
    }

    override func mouseDown(with event: NSEvent) {
        dragOrigin = NSEvent.mouseLocation
        isDragging = false
    }

    override func mouseDragged(with event: NSEvent) {
        let location = NSEvent.mouseLocation
        guard let origin = dragOrigin else { return }
        if !isDragging {
            let dx = location.x - origin.x
            let dy = location.y - origin.y
            if hypot(dx, dy) >= LayoutMetrics.dragThreshold {
                isDragging = true
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
        } else {
            onClick?()
        }
        dragOrigin = nil
        isDragging = false
    }
}
