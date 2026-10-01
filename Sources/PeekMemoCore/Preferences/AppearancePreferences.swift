import CoreGraphics
import Foundation

public enum ThemePreference: String, Codable, Sendable, CaseIterable {
    case system
    case light
    case dark
}

public enum EdgeTabColorMode: String, Codable, Sendable, CaseIterable {
    case systemAccent
    case custom
}

/// Memo-column width. The 14 pt hit rail is added beside it on Left / Right.
public enum PanelWidthPreset: String, Codable, Sendable, CaseIterable {
    case compact
    case medium
    case wide

    public var contentWidth: CGFloat {
        switch self {
        case .compact: 280
        case .medium: 340
        case .wide: 420
        }
    }
}

/// Maximum memo-column height, including the header. Short content shrinks below this.
public enum PanelHeightPreset: String, Codable, Sendable, CaseIterable {
    case small
    case medium
    case large

    public var maxContentHeight: CGFloat {
        switch self {
        case .small: 280
        case .medium: 420
        case .large: 560
        }
    }
}

/// Appearance and behavior. Persisted only through `PreferencesStore`.
public struct AppearancePreferences: Equatable, Sendable {
    public var theme: ThemePreference
    public var panelOpacity: Double
    public var panelWidthPreset: PanelWidthPreset
    public var panelHeightPreset: PanelHeightPreset
    public var edgeTabThickness: CGFloat
    public var edgeTabLength: CGFloat
    public var edgeTabColorMode: EdgeTabColorMode
    public var edgeTabCustomColor: RGBAColor
    public var edgeTabOpacity: Double
    public var hoverOpenDelay: TimeInterval
    public var hoverCloseDelay: TimeInterval
    public var reduceMotion: Bool
    public var launchAtLogin: Bool

    public static let defaultPanelOpacity = 0.94
    public static let defaultEdgeTabOpacity = 0.55
    public static let opacityRange = 0.70...1.00
    public static let edgeOpacityRange = 0.20...1.00
    public static let thicknessRange: ClosedRange<CGFloat> = 2...6
    public static let lengthRange: ClosedRange<CGFloat> = 32...96
    public static let openDelayChoices: [TimeInterval] = [0, 0.10, 0.16, 0.25, 0.40]
    public static let closeDelayChoices: [TimeInterval] = [0.15, 0.25, 0.35, 0.50, 0.75]
    public static let minimumContentHeight: CGFloat = 120
    public static let minimumBodyHeight: CGFloat = 40
    public static let hoverEmphasisBoost = 0.18

    public static let `default` = AppearancePreferences()

    public init(
        theme: ThemePreference = .system,
        panelOpacity: Double = defaultPanelOpacity,
        panelWidthPreset: PanelWidthPreset = .compact,
        panelHeightPreset: PanelHeightPreset = .medium,
        edgeTabThickness: CGFloat = LayoutMetrics.visibleTabThickness,
        edgeTabLength: CGFloat = LayoutMetrics.defaultStackLength,
        edgeTabColorMode: EdgeTabColorMode = .systemAccent,
        edgeTabCustomColor: RGBAColor = .accent,
        edgeTabOpacity: Double = defaultEdgeTabOpacity,
        hoverOpenDelay: TimeInterval = LayoutMetrics.defaultHoverOpenDelay,
        hoverCloseDelay: TimeInterval = LayoutMetrics.defaultHoverCloseDelay,
        reduceMotion: Bool = false,
        launchAtLogin: Bool = false
    ) {
        self.theme = theme
        self.panelOpacity = panelOpacity
        self.panelWidthPreset = panelWidthPreset
        self.panelHeightPreset = panelHeightPreset
        self.edgeTabThickness = edgeTabThickness
        self.edgeTabLength = edgeTabLength
        self.edgeTabColorMode = edgeTabColorMode
        self.edgeTabCustomColor = edgeTabCustomColor
        self.edgeTabOpacity = edgeTabOpacity
        self.hoverOpenDelay = hoverOpenDelay
        self.hoverCloseDelay = hoverCloseDelay
        self.reduceMotion = reduceMotion
        self.launchAtLogin = launchAtLogin
        self = clamped()
    }

    public func clamped() -> AppearancePreferences {
        var copy = self
        copy.panelOpacity = min(max(panelOpacity, Self.opacityRange.lowerBound), Self.opacityRange.upperBound)
        copy.edgeTabOpacity = min(max(edgeTabOpacity, Self.edgeOpacityRange.lowerBound), Self.edgeOpacityRange.upperBound)
        copy.edgeTabThickness = min(max(edgeTabThickness, Self.thicknessRange.lowerBound), Self.thicknessRange.upperBound)
        copy.edgeTabLength = min(max(edgeTabLength, Self.lengthRange.lowerBound), Self.lengthRange.upperBound)
        copy.hoverOpenDelay = Self.nearest(hoverOpenDelay, in: Self.openDelayChoices)
        copy.hoverCloseDelay = Self.nearest(hoverCloseDelay, in: Self.closeDelayChoices)
        return copy
    }

    /// Visual thickness never feeds this. Collapsed hit size stays `LayoutMetrics.hoverHitThickness`.
    public var hitRegionThickness: CGFloat {
        LayoutMetrics.hoverHitThickness
    }

    public static func nearest(_ value: TimeInterval, in choices: [TimeInterval]) -> TimeInterval {
        choices.min(by: { abs($0 - value) < abs($1 - value) }) ?? value
    }

    /// Header plus body, at least `minimumContentHeight`, and never above the height preset.
    public func contentColumnHeight(header: CGFloat, body: CGFloat) -> CGFloat {
        let natural = max(0, header) + max(0, body)
        let capped = min(natural, panelHeightPreset.maxContentHeight)
        return max(capped, Self.minimumContentHeight)
    }

    /// Scroll viewport for the memo body. Short content keeps its natural height.
    public func bodyViewport(header: CGFloat, body: CGFloat) -> CGFloat {
        let header = max(0, header)
        let body = max(0, body)
        let maxHeight = panelHeightPreset.maxContentHeight
        if header + body <= maxHeight {
            return body
        }
        return max(Self.minimumBodyHeight, maxHeight - header)
    }

    public func expandedWindowSize(edgeIsVertical: Bool, header: CGFloat, body: CGFloat) -> CGSize {
        let column = contentColumnHeight(header: header, body: body)
        let contentWidth = panelWidthPreset.contentWidth
        if edgeIsVertical {
            return CGSize(width: contentWidth + hitRegionThickness, height: column)
        }
        return CGSize(width: contentWidth, height: column + hitRegionThickness)
    }

    /// Hover raises the wedge only. The hit window and the panel alpha stay put.
    public static func displayedEdgeTabOpacity(base: Double, emphasized: Bool) -> Double {
        let clamped = min(max(base, edgeOpacityRange.lowerBound), edgeOpacityRange.upperBound)
        guard emphasized else { return clamped }
        return min(1, clamped + hoverEmphasisBoost)
    }
}
