import CoreGraphics
import Foundation

/// Canonical layout and interaction numbers. Do not scatter these as literals.
public enum LayoutMetrics: Sendable {
    /// Distance from a screen edge at which a drag magnetically snaps.
    public static let magnetRange: CGFloat = 24

    /// Pointer movement required before a press becomes a drag.
    public static let dragThreshold: CGFloat = 6

    /// Visible thickness of the Edge Tab wedge, in points.
    public static let visibleTabThickness: CGFloat = 4

    /// Mouse-tracking thickness of the collapsed window, in points.
    public static let hoverHitThickness: CGFloat = 14

    public static let defaultHoverOpenDelay: TimeInterval = 0.15
    public static let defaultHoverCloseDelay: TimeInterval = 0.35

    /// Handle reveal. Keep inside 100–180 ms.
    public static let handleRevealDuration: TimeInterval = 0.14

    /// Panel expand / collapse. Keep inside 120–220 ms.
    public static let panelAnimationDuration: TimeInterval = 0.16

    public static let defaultPanelWidth: CGFloat = 280
    public static let defaultPanelHeight: CGFloat = 360

    public static let defaultStackLength: CGFloat = 96
    public static let defaultOpacity: Double = 0.92
    public static let minimumOpacity: Double = 0.5
    public static let maximumOpacity: Double = 1.0
}
