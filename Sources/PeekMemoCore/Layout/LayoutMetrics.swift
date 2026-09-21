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

    /// Horizontal distance from the notch at which Top-edge drag starts pulling toward cloak.
    public static let notchSnapThreshold: CGFloat = 26

    /// Notch Cloak draws nothing. The housing occludes the window.
    public static let notchCloakVisibleThickness: CGFloat = 0

    /// If native hit-testing inside the cutout fails, extend this many points below `notchRect.minY`.
    /// Keep at 2–4 pt. Never a 14 pt underside bar.
    public static let notchActivationExtension: CGFloat = 3

    /// Extra padding around the union of tab + panel so a 1–2 px animation gap does not collapse hover.
    public static let hoverRegionPadding: CGFloat = 6

    /// Delay after mouse-exit before the engine is told the pointer left.
    public static let hoverGracePeriod: TimeInterval = 0.08

    public static let defaultHoverOpenDelay: TimeInterval = 0.16
    public static let defaultHoverCloseDelay: TimeInterval = 0.35

    /// Handle reveal. Keep inside 100–180 ms.
    public static let handleRevealDuration: TimeInterval = 0.14

    /// Panel expand / collapse. Keep inside 120–220 ms.
    public static let panelAnimationDuration: TimeInterval = 0.16

    public static let defaultPanelWidth: CGFloat = 280
    public static let defaultPanelHeight: CGFloat = 360
    public static let previewPanelWidth: CGFloat = 260
    public static let previewPanelHeight: CGFloat = 228

    public static let defaultStackLength: CGFloat = 96
    public static let defaultOpacity: Double = 0.92
    public static let minimumOpacity: Double = 0.5
    public static let maximumOpacity: Double = 1.0
}
