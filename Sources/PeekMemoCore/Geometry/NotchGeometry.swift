import CoreGraphics
import Foundation

/// Derives the camera-housing / notch rectangle from portable screen metrics.
/// Never uses a Mac model name or a hard-coded resolution.
public enum NotchGeometry: Sendable {
    /// Horizontal overlap ratio at which a stored top-edge drop is treated as Notch Cloak.
    public static let cloakOverlapRatio: CGFloat = 0.5

    public static func region(on screen: ScreenGeometry) -> NotchRegion? {
        region(
            screenFrame: screen.frame,
            safeAreaInsets: screen.safeAreaInsets,
            auxiliaryTopLeft: screen.auxiliaryTopLeft,
            auxiliaryTopRight: screen.auxiliaryTopRight
        )
    }

    public static func region(
        screenFrame: CGRect,
        safeAreaInsets: EdgeInsetsLTRB,
        auxiliaryTopLeft: CGRect?,
        auxiliaryTopRight: CGRect?
    ) -> NotchRegion? {
        guard safeAreaInsets.top > 0,
              let left = meaningful(auxiliaryTopLeft),
              let right = meaningful(auxiliaryTopRight)
        else {
            return nil
        }

        let minX = left.maxX
        let maxX = right.minX
        let width = maxX - minX
        let height = safeAreaInsets.top
        guard width > 1, height > 0 else {
            return nil
        }

        let frame = CGRect(
            x: minX,
            y: screenFrame.maxY - height,
            width: width,
            height: height
        )
        return NotchRegion(frame: frame)
    }

    /// Horizontal band of the notch in screen space.
    public static func horizontalRange(on screen: ScreenGeometry) -> ClosedRange<CGFloat>? {
        guard let notch = region(on: screen) else { return nil }
        return notch.frame.minX...notch.frame.maxX
    }

    /// Distance from `x` to the notch’s horizontal span. Zero when inside.
    public static func horizontalDistance(_ x: CGFloat, to notch: CGRect) -> CGFloat {
        if x < notch.minX { return notch.minX - x }
        if x > notch.maxX { return x - notch.maxX }
        return 0
    }

    /// Transparent tracking strip on the notch underside. Does not cover the housing itself.
    public static func undersideHitRect(for notch: NotchRegion) -> CGRect {
        CGRect(
            x: notch.frame.minX,
            y: notch.frame.minY - LayoutMetrics.notchCloakHitThickness,
            width: notch.frame.width,
            height: LayoutMetrics.notchCloakHitThickness
        )
    }

    /// True when a top-edge stack at `offset` overlaps the notch enough to cloak.
    public static func shouldCloak(
        edge: ScreenEdge,
        offset: CGFloat,
        stackLength: CGFloat,
        screen: ScreenGeometry
    ) -> Bool {
        guard edge == .top, let notch = region(on: screen) else {
            return false
        }
        let handleMinX = screen.visibleFrame.minX + offset
        let handle = CGRect(x: handleMinX, y: 0, width: stackLength, height: 1)
        let notchBand = CGRect(x: notch.frame.minX, y: 0, width: notch.frame.width, height: 1)
        let overlap = handle.intersection(notchBand).width
        guard overlap > 0 else {
            return false
        }
        let threshold = min(stackLength, notch.frame.width) * cloakOverlapRatio
        return overlap >= threshold
    }

    /// Pointer is on the top edge and inside the notch’s horizontal span.
    public static func pointerCommitsCloak(
        _ pointer: CGPoint,
        screen: ScreenGeometry,
        magnetRange: CGFloat = LayoutMetrics.magnetRange
    ) -> Bool {
        guard let notch = region(on: screen) else { return false }
        let distanceToTop = abs(pointer.y - screen.frame.maxY)
        guard distanceToTop <= magnetRange else { return false }
        return horizontalDistance(pointer.x, to: notch.frame) == 0
    }

    /// 0 outside the magnet, 1 inside the notch, smoothstep in between.
    public static func cloakPull(
        pointer: CGPoint,
        screen: ScreenGeometry,
        magnetRange: CGFloat = LayoutMetrics.magnetRange,
        snapThreshold: CGFloat = LayoutMetrics.notchSnapThreshold
    ) -> CGFloat {
        guard let notch = region(on: screen) else { return 0 }
        let distanceToTop = abs(pointer.y - screen.frame.maxY)
        guard distanceToTop <= magnetRange else { return 0 }
        let distX = horizontalDistance(pointer.x, to: notch.frame)
        if distX == 0 { return 1 }
        if distX >= snapThreshold { return 0 }
        let t = 1 - distX / snapThreshold
        return t * t * (3 - 2 * t)
    }

    /// Offset that centers a stack on the notch, clamped to the top visible span.
    public static func cloakOffset(stackLength: CGFloat, screen: ScreenGeometry) -> CGFloat {
        guard let notch = region(on: screen) else {
            return 0
        }
        let centered = notch.frame.midX - stackLength / 2 - screen.visibleFrame.minX
        return EdgeGeometry.clampOffset(centered, edge: .top, screen: screen, stackLength: stackLength)
    }

    private static func meaningful(_ rect: CGRect?) -> CGRect? {
        guard let rect, !rect.isNull, !rect.isInfinite, rect.width > 0, rect.height > 0 else {
            return nil
        }
        return rect
    }
}
