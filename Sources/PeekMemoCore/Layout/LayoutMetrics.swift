import CoreGraphics
import Foundation

/// Canonical layout and interaction numbers. Do not scatter these as literals.
public enum LayoutMetrics: Sendable {
    /// Distance from a screen edge at which a drag magnetically snaps.
    public static let magnetRange: CGFloat = 24

    /// Pointer movement required before a press becomes a drag.
    public static let dragThreshold: CGFloat = 6

    /// Visible thickness of the Edge Tab wedge, in points.
    public static let visibleTabThickness: CGFloat = 3

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

    /// Handle reveal. About 100 ms.
    public static let handleRevealDuration: TimeInterval = 0.10

    /// Panel expand. 180–220 ms.
    public static let expandDuration: TimeInterval = 0.20

    /// Panel collapse. 150–190 ms.
    public static let collapseDuration: TimeInterval = 0.17

    /// Content fade starts this long after the shell begins expanding.
    public static let contentFadeDelay: TimeInterval = 0.04

    /// Brief content fade before the shell collapses.
    public static let contentFadeOutDuration: TimeInterval = 0.05

    /// Legacy alias used by a few call sites; prefer expand/collapse durations.
    public static let panelAnimationDuration: TimeInterval = expandDuration

    public static let defaultPanelWidth: CGFloat = 280
    public static let defaultPanelHeight: CGFloat = 360
    public static let previewPanelWidth: CGFloat = 280
    public static let previewPanelHeight: CGFloat = 320

    public static let defaultStackLength: CGFloat = 56
    public static let subtaskIndent: CGFloat = 18
    public static let defaultOpacity: Double = 0.92
    public static let minimumOpacity: Double = 0.5
    public static let maximumOpacity: Double = 1.0
}
