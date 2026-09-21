import CoreGraphics
import Foundation

/// Pure frame interpolation. The window’s contact edge is invariant for the whole motion.
public enum PanelAnimator: Sendable {
    public static func interpolated(from: CGRect, to: CGRect, progress: CGFloat) -> CGRect {
        let t = min(max(progress, 0), 1)
        return CGRect(
            x: from.origin.x + (to.origin.x - from.origin.x) * t,
            y: from.origin.y + (to.origin.y - from.origin.y) * t,
            width: from.size.width + (to.size.width - from.size.width) * t,
            height: from.size.height + (to.size.height - from.size.height) * t
        )
    }

    /// The screen edge that must not move during expand/collapse.
    public static func fixedEdge(for placement: PanelPlacement) -> ScreenEdge {
        placement.isNotchCloak ? .top : placement.edge
    }

    public static func edgeCoordinate(_ edge: ScreenEdge, of rect: CGRect) -> CGFloat {
        switch edge {
        case .left: rect.minX
        case .right: rect.maxX
        case .bottom: rect.minY
        case .top: rect.maxY
        }
    }

    public static func fixedEdgeHolds(
        from: CGRect,
        to: CGRect,
        edge: ScreenEdge,
        tolerance: CGFloat = 0.5
    ) -> Bool {
        let a = edgeCoordinate(edge, of: from)
        let b = edgeCoordinate(edge, of: to)
        let mid = edgeCoordinate(edge, of: interpolated(from: from, to: to, progress: 0.5))
        return abs(a - b) <= tolerance && abs(mid - a) <= tolerance
    }
}
