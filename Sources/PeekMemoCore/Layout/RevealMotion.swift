import CoreGraphics
import Foundation

/// Edge reveal content scale. Reduce Motion keeps the content at full size.
public enum RevealMotion: Sendable {
    public static let minimumScale: CGFloat = 0.96

    public static func contentScale(opacity: Double, reduceMotion: Bool) -> CGFloat {
        guard !reduceMotion else { return 1 }
        let progress = min(max(opacity, 0), 1)
        return minimumScale + (1 - minimumScale) * progress
    }
}
