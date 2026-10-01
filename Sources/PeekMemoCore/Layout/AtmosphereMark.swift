import CoreGraphics
import Foundation

/// Faint corner artwork. It never takes layout space and never sits above the tasks.
public enum AtmosphereMark: Sendable {
    public static let minimumWidthFraction: CGFloat = 0.22
    public static let maximumWidthFraction: CGFloat = 0.32
    public static let darkOpacity: CGFloat = 0.20
    public static let lightOpacity: CGFloat = 0.12
    /// Share of the mark that may sit past the panel corner.
    public static let bleedFraction: CGFloat = 0.14

    public struct Layout: Equatable, Sendable {
        public var width: CGFloat
        public var opacity: CGFloat
        public var bleed: CGFloat

        public init(width: CGFloat, opacity: CGFloat, bleed: CGFloat) {
            self.width = width
            self.opacity = opacity
            self.bleed = bleed
        }
    }

    public static func layout(panelWidth: CGFloat, panelHeight: CGFloat, lightBackground: Bool) -> Layout {
        let width = max(panelWidth, 0)
        let height = max(panelHeight, 0)
        guard width >= 1, height >= 1 else {
            return Layout(width: 0, opacity: 0, bleed: 0)
        }

        let fraction: CGFloat
        if width < 280 {
            fraction = minimumWidthFraction * (width / 280)
        } else {
            let t = min(max((width - 280) / 180, 0), 1)
            fraction = 0.24 + (maximumWidthFraction - 0.24) * t
        }

        var fitted = fraction
        if height < 460 {
            fitted *= max(0.35, height / 460)
        }
        fitted = min(fitted, maximumWidthFraction)

        var opacity = lightBackground ? lightOpacity : darkOpacity
        if height < 340 {
            opacity *= max(0.15, height / 340)
        }
        if width < 260 {
            opacity *= max(0.25, width / 260)
        }
        if height < 220 || width < 200 {
            opacity *= 0.35
        }
        opacity = min(max(opacity, 0), darkOpacity)

        let markWidth = width * fitted
        return Layout(width: markWidth, opacity: opacity, bleed: markWidth * bleedFraction)
    }
}
