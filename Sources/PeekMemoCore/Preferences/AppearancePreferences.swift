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

/// Appearance and behavior. Persisted only through `PreferencesStore`.
public struct AppearancePreferences: Equatable, Sendable {
    public var theme: ThemePreference
    public var panelOpacity: Double
    public var panelSizeMode: PanelSizeMode
    public var panelWidth: CGFloat
    public var panelHeight: CGFloat
    public var backgroundMode: PanelBackgroundMode
    public var backgroundSolidColor: RGBAColor
    public var backgroundSolidOpacity: Double
    public var backgroundImageFilename: String?
    public var backgroundImageContentMode: BackgroundImageContentMode
    public var backgroundImagePosition: BackgroundImagePosition
    public var backgroundImageOpacity: Double
    public var backgroundOverlayOpacity: Double
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
    public static let solidOpacityRange = 0.40...1.00
    public static let imageOpacityRange = 0.20...1.00
    public static let overlayOpacityRange = 0.0...0.80
    public static let defaultBackgroundSolidOpacity = 1.0
    public static let defaultImageOpacity = 0.60
    public static let defaultOverlayOpacity = 0.25
    public static let defaultSolidColor = RGBAColor(red: 0.965, green: 0.953, blue: 0.925)
    public static let thicknessRange: ClosedRange<CGFloat> = 2...6
    public static let lengthRange: ClosedRange<CGFloat> = 32...96
    public static let openDelayChoices: [TimeInterval] = [0, 0.10, 0.16, 0.25, 0.40]
    public static let closeDelayChoices: [TimeInterval] = [0.15, 0.25, 0.35, 0.50, 0.75]
    public static let hoverEmphasisBoost = 0.18

    public static let `default` = AppearancePreferences()

    public init(
        theme: ThemePreference = .system,
        panelOpacity: Double = defaultPanelOpacity,
        panelSizeMode: PanelSizeMode = .medium,
        panelWidth: CGFloat = PanelSizeMetrics.defaultWidth,
        panelHeight: CGFloat = PanelSizeMetrics.defaultHeight,
        backgroundMode: PanelBackgroundMode = .systemMaterial,
        backgroundSolidColor: RGBAColor = defaultSolidColor,
        backgroundSolidOpacity: Double = defaultBackgroundSolidOpacity,
        backgroundImageFilename: String? = nil,
        backgroundImageContentMode: BackgroundImageContentMode = .fill,
        backgroundImagePosition: BackgroundImagePosition = .center,
        backgroundImageOpacity: Double = defaultImageOpacity,
        backgroundOverlayOpacity: Double = defaultOverlayOpacity,
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
        self.panelSizeMode = panelSizeMode
        self.panelWidth = panelWidth
        self.panelHeight = panelHeight
        self.backgroundMode = backgroundMode
        self.backgroundSolidColor = backgroundSolidColor
        self.backgroundSolidOpacity = backgroundSolidOpacity
        self.backgroundImageFilename = backgroundImageFilename
        self.backgroundImageContentMode = backgroundImageContentMode
        self.backgroundImagePosition = backgroundImagePosition
        self.backgroundImageOpacity = backgroundImageOpacity
        self.backgroundOverlayOpacity = backgroundOverlayOpacity
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
        if copy.panelSizeMode == .custom {
            let stored = PanelSizeMetrics.clampStored(PanelContentSize(width: panelWidth, height: panelHeight))
            copy.panelWidth = stored.width
            copy.panelHeight = stored.height
        } else {
            let preset = PanelSizeMetrics.preset(copy.panelSizeMode)
            copy.panelWidth = preset.width
            copy.panelHeight = preset.height
        }
        copy.backgroundSolidOpacity = min(
            max(backgroundSolidOpacity, Self.solidOpacityRange.lowerBound),
            Self.solidOpacityRange.upperBound
        )
        if let name = backgroundImageFilename, !BackgroundImageStore.isSafeFilename(name) {
            copy.backgroundImageFilename = nil
        }
        copy.backgroundImageOpacity = min(
            max(backgroundImageOpacity, Self.imageOpacityRange.lowerBound),
            Self.imageOpacityRange.upperBound
        )
        copy.backgroundOverlayOpacity = min(
            max(backgroundOverlayOpacity, Self.overlayOpacityRange.lowerBound),
            Self.overlayOpacityRange.upperBound
        )
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

    /// Preferred card size. Short lists do not shrink this. The screen clamp is display-only.
    public var contentSize: PanelContentSize {
        PanelContentSize(width: panelWidth, height: panelHeight)
    }

    public func displayContentSize(visible: CGSize, edgeIsVertical: Bool) -> PanelContentSize {
        PanelSizeMetrics.clampToScreen(contentSize, visible: visible, edgeIsVertical: edgeIsVertical)
    }

    public func windowSize(edgeIsVertical: Bool, visible: CGSize) -> CGSize {
        PanelSizeMetrics.windowSize(
            content: displayContentSize(visible: visible, edgeIsVertical: edgeIsVertical),
            edgeIsVertical: edgeIsVertical
        )
    }

    public var sizeLabel: String {
        "\(Int(panelWidth.rounded())) × \(Int(panelHeight.rounded()))"
    }

    /// Hover raises the wedge only. The hit window and the panel alpha stay put.
    public static func displayedEdgeTabOpacity(base: Double, emphasized: Bool) -> Double {
        let clamped = min(max(base, edgeOpacityRange.lowerBound), edgeOpacityRange.upperBound)
        guard emphasized else { return clamped }
        return min(1, clamped + hoverEmphasisBoost)
    }
}
