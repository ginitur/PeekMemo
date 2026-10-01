import CoreGraphics
import Foundation

public enum ResizeGripCorner: Sendable, Equatable {
    case bottomLeft
    case bottomRight
    case topLeft
    case topRight
}

/// Resize grip sits in the content card, away from the screen edge and the drag rail.
public enum PanelResizeGeometry: Sendable {
    /// Mouse target. The view must be this size, not the card.
    public static let gripSize: CGFloat = 22
    public static let maximumHitSize: CGFloat = 24
    /// The three ticks. Drawing only; it does not grow the hit target.
    public static let visualGripSize: CGFloat = 14
    public static let gripInset: CGFloat = 6

    /// Right: bottom-left. Left: bottom-right. Bottom: top-right. Top stays experimental.
    public static func corner(for edge: ScreenEdge) -> ResizeGripCorner {
        switch edge {
        case .right: .bottomLeft
        case .left: .bottomRight
        case .bottom: .topRight
        case .top: .bottomRight
        }
    }

    /// Content card inside the window. The hit rail is excluded.
    public static func contentRect(in window: CGRect, edge: ScreenEdge) -> CGRect {
        let hit = LayoutMetrics.hoverHitThickness
        switch edge {
        case .right:
            return CGRect(x: window.minX, y: window.minY, width: max(0, window.width - hit), height: window.height)
        case .left:
            return CGRect(x: window.minX + hit, y: window.minY, width: max(0, window.width - hit), height: window.height)
        case .bottom:
            return CGRect(x: window.minX, y: window.minY + hit, width: window.width, height: max(0, window.height - hit))
        case .top:
            return CGRect(x: window.minX, y: window.minY, width: window.width, height: max(0, window.height - hit))
        }
    }

    /// Places the hit square in a corner of `bounds`.
    /// `bounds` is flipped: origin top-left, y grows downward, matching `PanelResizeGripView`.
    /// A bounds the size of the card still returns only the corner square.
    public static func flippedHitRect(in bounds: CGRect, corner: ResizeGripCorner) -> CGRect {
        let side = min(gripSize, maximumHitSize, max(bounds.width, 0), max(bounds.height, 0))
        switch corner {
        case .bottomLeft:
            return CGRect(x: bounds.minX, y: bounds.maxY - side, width: side, height: side)
        case .bottomRight:
            return CGRect(x: bounds.maxX - side, y: bounds.maxY - side, width: side, height: side)
        case .topLeft:
            return CGRect(x: bounds.minX, y: bounds.minY, width: side, height: side)
        case .topRight:
            return CGRect(x: bounds.maxX - side, y: bounds.minY, width: side, height: side)
        }
    }

    /// AppKit coordinates, origin bottom-left, in the same space as `content`.
    public static func gripFrame(in content: CGRect, edge: ScreenEdge) -> CGRect {
        let size = gripSize
        let inset = gripInset
        switch corner(for: edge) {
        case .bottomLeft:
            return CGRect(x: content.minX + inset, y: content.minY + inset, width: size, height: size)
        case .bottomRight:
            return CGRect(x: content.maxX - inset - size, y: content.minY + inset, width: size, height: size)
        case .topLeft:
            return CGRect(x: content.minX + inset, y: content.maxY - inset - size, width: size, height: size)
        case .topRight:
            return CGRect(x: content.maxX - inset - size, y: content.maxY - inset - size, width: size, height: size)
        }
    }

    public struct ContentProbe: Equatable, Sendable {
        public var resizeHandleRect: CGRect
        public var dateHeader: CGPoint
        public var categoryButton: CGPoint
        public var taskRow: CGPoint
        public var addTask: CGPoint
        public var center: CGPoint
        public var corner: CGPoint

        public init(
            resizeHandleRect: CGRect,
            dateHeader: CGPoint,
            categoryButton: CGPoint,
            taskRow: CGPoint,
            addTask: CGPoint,
            center: CGPoint,
            corner: CGPoint
        ) {
            self.resizeHandleRect = resizeHandleRect
            self.dateHeader = dateHeader
            self.categoryButton = categoryButton
            self.taskRow = taskRow
            self.addTask = addTask
            self.center = center
            self.corner = corner
        }

        public func hitsResize(_ point: CGPoint) -> Bool {
            resizeHandleRect.contains(point)
        }
    }

    /// Sample points on a memo card. Only `corner` may lie inside the grip.
    /// Coordinates match `gripFrame`: origin bottom-left.
    public static func contentProbe(content: CGRect, edge: ScreenEdge) -> ContentProbe {
        let handle = gripFrame(in: content, edge: edge)
        return ContentProbe(
            resizeHandleRect: handle,
            dateHeader: CGPoint(x: content.minX + 72, y: content.maxY - 24),
            categoryButton: CGPoint(x: content.maxX - 40, y: content.maxY - 24),
            taskRow: CGPoint(x: content.minX + 48, y: content.midY),
            addTask: CGPoint(x: content.midX, y: content.minY + 18),
            center: CGPoint(x: content.midX, y: content.midY),
            corner: CGPoint(x: handle.midX, y: handle.midY)
        )
    }

    public static func beginsResize(at point: CGPoint, content: CGRect, edge: ScreenEdge) -> Bool {
        gripFrame(in: content, edge: edge).contains(point)
    }

    /// SwiftUI translation: positive x is right, positive y is down.
    /// The contact edge stays fixed. Width and height change independently.
    public static func resizedContent(
        start: PanelContentSize,
        translation: CGSize,
        edge: ScreenEdge,
        visible: CGSize
    ) -> PanelContentSize {
        var width = start.width
        var height = start.height
        switch edge {
        case .right:
            width = start.width - translation.width
            height = start.height + translation.height
        case .left:
            width = start.width + translation.width
            height = start.height + translation.height
        case .bottom:
            width = start.width + translation.width
            height = start.height - translation.height
        case .top:
            width = start.width + translation.width
            height = start.height + translation.height
        }
        return PanelSizeMetrics.clampToScreen(
            PanelContentSize(width: width, height: height),
            visible: visible,
            edgeIsVertical: edge.isVertical
        )
    }
}
