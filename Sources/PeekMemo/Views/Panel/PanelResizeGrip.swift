import AppKit
import PeekMemoCore
import SwiftUI

/// Corner grip. The SwiftUI frame and `sizeThatFits` are both 22×22.
/// There is no drag gesture on the panel, the overlay, or a geometry reader.
struct PanelResizeGrip: NSViewRepresentable {
    var corner: ResizeGripCorner
    var showRegion: Bool = false
    var onBegan: () -> Void = {}
    var onChanged: () -> Void = {}
    var onEnded: () -> Void = {}

    func makeNSView(context: Context) -> PanelResizeGripView {
        let view = PanelResizeGripView()
        view.corner = corner
        view.showRegion = showRegion
        view.onBegan = onBegan
        view.onChanged = onChanged
        view.onEnded = onEnded
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentHuggingPriority(.required, for: .vertical)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        view.setAccessibilityElement(true)
        view.setAccessibilityRole(.button)
        view.setAccessibilityLabel("Resize panel")
        return view
    }

    func updateNSView(_ view: PanelResizeGripView, context: Context) {
        view.corner = corner
        view.showRegion = showRegion
        view.onBegan = onBegan
        view.onChanged = onChanged
        view.onEnded = onEnded
        view.needsDisplay = true
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        nsView: PanelResizeGripView,
        context: Context
    ) -> CGSize? {
        CGSize(width: PanelResizeGeometry.gripSize, height: PanelResizeGeometry.gripSize)
    }
}

final class PanelResizeGripView: NSView {
    var corner: ResizeGripCorner = .bottomLeft {
        didSet { needsLayout = true }
    }
    var showRegion = false
    var onBegan: () -> Void = {}
    var onChanged: () -> Void = {}
    var onEnded: () -> Void = {}
    private var hovering = false
    private var dragging = false
    #if DEBUG
    private var lastResizeLogKey: String?
    #endif

    override var isFlipped: Bool { true }

    override var intrinsicContentSize: NSSize {
        NSSize(width: PanelResizeGeometry.gripSize, height: PanelResizeGeometry.gripSize)
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    /// Only this square is a hit target, even if a layout pass gives the view a larger frame.
    var hitRect: CGRect {
        PanelResizeGeometry.flippedHitRect(in: bounds, corner: corner)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        let hit = hitRect.contains(local)
        logResize(hit: hit)
        return hit ? self : nil
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        window?.invalidateCursorRects(for: self)
        logResize(hit: hovering || dragging)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas {
            removeTrackingArea(area)
        }
        addTrackingArea(NSTrackingArea(
            rect: hitRect,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil
        ))
    }

    override func resetCursorRects() {
        addCursorRect(hitRect, cursor: resizeCursor)
    }

    override func mouseEntered(with event: NSEvent) {
        hovering = true
        resizeCursor.set()
        logResize(hit: true)
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        hovering = false
        if !dragging {
            NSCursor.arrow.set()
        }
        logResize(hit: dragging)
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        let local = convert(event.locationInWindow, from: nil)
        guard hitRect.contains(local) else { return }
        dragging = true
        resizeCursor.set()
        logResize(hit: true)
        onBegan()
    }

    override func mouseDragged(with event: NSEvent) {
        guard dragging else { return }
        onChanged()
    }

    override func mouseUp(with event: NSEvent) {
        guard dragging else { return }
        dragging = false
        if !hovering {
            NSCursor.arrow.set()
        }
        logResize(hit: hovering)
        onEnded()
    }

    override func draw(_ dirtyRect: NSRect) {
        if showRegion {
            NSColor.systemPurple.withAlphaComponent(0.28).setFill()
            NSBezierPath(rect: hitRect).fill()
        }
        let color = NSColor.labelColor.withAlphaComponent(hovering || dragging ? 0.55 : 0.22)
        color.setStroke()
        let path = NSBezierPath()
        path.lineWidth = 1.25
        path.lineCapStyle = .round
        let rect = visualRect.insetBy(dx: 1, dy: 1)
        for scale in [CGFloat(0.38), 0.62, 0.86] {
            let along = min(rect.width, rect.height) * scale
            switch corner {
            case .bottomLeft:
                path.move(to: CGPoint(x: rect.minX, y: rect.maxY - along))
                path.line(to: CGPoint(x: rect.minX + along, y: rect.maxY))
            case .bottomRight:
                path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - along))
                path.line(to: CGPoint(x: rect.maxX - along, y: rect.maxY))
            case .topLeft:
                path.move(to: CGPoint(x: rect.minX, y: rect.minY + along))
                path.line(to: CGPoint(x: rect.minX + along, y: rect.minY))
            case .topRight:
                path.move(to: CGPoint(x: rect.maxX, y: rect.minY + along))
                path.line(to: CGPoint(x: rect.maxX - along, y: rect.minY))
            }
        }
        path.stroke()
    }

    /// Ticks stay inside 14×14. They are not scaled to the card.
    private var visualRect: CGRect {
        let hit = hitRect
        let side = min(PanelResizeGeometry.visualGripSize, hit.width, hit.height)
        return CGRect(
            x: hit.midX - side / 2,
            y: hit.midY - side / 2,
            width: side,
            height: side
        )
    }

    private var resizeCursor: NSCursor {
        guard #available(macOS 15.0, *) else { return .crosshair }
        let position: NSCursor.FrameResizePosition
        switch corner {
        case .bottomLeft: position = .bottomLeft
        case .bottomRight: position = .bottomRight
        case .topLeft: position = .topLeft
        case .topRight: position = .topRight
        }
        return NSCursor.frameResize(position: position, directions: .all)
    }

    private func logResize(hit: Bool) {
        #if DEBUG
        guard let window else { return }
        let panelBounds = window.contentView?.bounds ?? bounds
        let handle = convert(hitRect, to: nil)
        let mouse = NSEvent.mouseLocation
        let key = "\(Int(handle.width.rounded()))x\(Int(handle.height.rounded()))|\(hit)"
        guard key != lastResizeLogKey else { return }
        lastResizeLogKey = key
        print(
            """
            [Resize]
            panelBounds=\(NSStringFromRect(panelBounds))
            resizeHandleRect=\(NSStringFromRect(handle))
            mouse=\(NSStringFromPoint(mouse))
            hitResize=\(hit)
            """
        )
        #endif
    }
}
