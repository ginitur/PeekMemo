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
}
