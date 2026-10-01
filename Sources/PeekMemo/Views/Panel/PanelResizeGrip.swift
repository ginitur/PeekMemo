import AppKit
import PeekMemoCore
import SwiftUI

/// Draws its own hover. No SwiftUI `@State`, so the grip does not depend on the SwiftUI macro plugin.
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
}

final class PanelResizeGripView: NSView {
    var corner: ResizeGripCorner = .bottomLeft
    var showRegion = false
    var onBegan: () -> Void = {}
    var onChanged: () -> Void = {}
    var onEnded: () -> Void = {}
    private var hovering = false
    private var dragging = false

    override var isFlipped: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas {
            removeTrackingArea(area)
        }
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        ))
    }

    override func mouseEntered(with event: NSEvent) {
        hovering = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        hovering = false
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        dragging = true
        onBegan()
    }

    override func mouseDragged(with event: NSEvent) {
        guard dragging else { return }
        onChanged()
    }

    override func mouseUp(with event: NSEvent) {
        guard dragging else { return }
        dragging = false
        onEnded()
    }

    override func draw(_ dirtyRect: NSRect) {
        if showRegion {
            NSColor.systemPurple.withAlphaComponent(0.28).setFill()
            bounds.fill()
        }
        let color = NSColor.labelColor.withAlphaComponent(hovering ? 0.55 : 0.22)
        color.setStroke()
        let path = NSBezierPath()
        path.lineWidth = 1.25
        path.lineCapStyle = .round
        let rect = bounds.insetBy(dx: 1, dy: 1)
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
}
