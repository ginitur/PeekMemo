import CoreGraphics
import Foundation

/// Union of the Edge Tab and Expanded Panel, plus padding for animation gaps.
public enum HoverRegion: Sendable {
    public static func frame(
        collapsed: CGRect,
        expanded: CGRect,
        phase: HoverPhase,
        padding: CGFloat = LayoutMetrics.hoverRegionPadding
    ) -> CGRect {
        let base: CGRect = switch phase {
        case .collapsed, .hovering:
            collapsed
        case .expanded, .pinned, .editing:
            collapsed.union(expanded)
        }
        return base.insetBy(dx: -padding, dy: -padding)
    }

    public static func contains(
        _ point: CGPoint,
        collapsed: CGRect,
        expanded: CGRect,
        phase: HoverPhase,
        padding: CGFloat = LayoutMetrics.hoverRegionPadding
    ) -> Bool {
        frame(collapsed: collapsed, expanded: expanded, phase: phase, padding: padding).contains(point)
    }

    /// Edge and panel are tested separately. Unioning them would treat the gap
    /// between a stale edge frame and the live panel as inside.
    public static func hits(
        _ point: CGPoint,
        edge: CGRect,
        panel: CGRect?,
        padding: CGFloat = LayoutMetrics.hoverRegionPadding
    ) -> HoverPointerHits {
        let edgeRect = edge.insetBy(dx: -padding, dy: -padding)
        let insideEdge = edgeRect.contains(point)
        let insidePanel = panel?.insetBy(dx: -padding, dy: -padding).contains(point) ?? false
        return HoverPointerHits(insideEdge: insideEdge, insidePanel: insidePanel)
    }
}

public struct HoverPointerHits: Equatable, Sendable {
    public var insideEdge: Bool
    public var insidePanel: Bool

    public var inside: Bool { insideEdge || insidePanel }

    public init(insideEdge: Bool, insidePanel: Bool) {
        self.insideEdge = insideEdge
        self.insidePanel = insidePanel
    }
}
