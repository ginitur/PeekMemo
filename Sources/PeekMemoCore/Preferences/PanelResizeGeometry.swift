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
    public static let gripSize: CGFloat = 22
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
