import CoreGraphics
import Foundation

/// Derives the camera-housing / notch rectangle from portable screen metrics.
/// Never uses a Mac model name or a hard-coded resolution.
public enum NotchGeometry: Sendable {
    /// Horizontal overlap ratio at which a top-edge drop is treated as Notch Cloak.
    public static let cloakOverlapRatio: CGFloat = 0.5

    public static func region(on screen: ScreenGeometry) -> NotchRegion? {
        guard screen.safeAreaInsets.top > 0,
              let left = Self.meaningful(screen.auxiliaryTopLeft),
              let right = Self.meaningful(screen.auxiliaryTopRight)
        else {
            return nil
        }

        let minX = left.maxX
        let maxX = right.minX
        let width = maxX - minX
        let height = screen.safeAreaInsets.top
        guard width > 1, height > 0 else {
            return nil
        }

        let frame = CGRect(
            x: minX,
            y: screen.frame.maxY - height,
            width: width,
            height: height
        )
        return NotchRegion(frame: frame)
    }

    /// True when a top-edge stack at `offset` should enter Notch Cloak.
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
