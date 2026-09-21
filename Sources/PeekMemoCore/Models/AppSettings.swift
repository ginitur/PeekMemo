import CoreGraphics
import Foundation

public enum AppearanceMode: String, Codable, Sendable, CaseIterable {
    case system
    case light
    case dark
}

public enum EdgeItemShape: String, Codable, Sendable, CaseIterable {
    case circle
    case roundedSquare
    case pill
}

public enum EdgeItemSize: String, Codable, Sendable, CaseIterable {
    case small
    case medium
    case large

    public var pointSize: CGFloat {
        switch self {
        case .small: 18
        case .medium: 24
        case .large: 30
        }
    }
}

public enum CollapsedMode: String, Codable, Sendable, CaseIterable {
    case edgeTab
    case cloak
    case notchCloak
}

public struct AppSettings: Equatable, Sendable, Codable {
    public var selectedEdge: ScreenEdge
    public var edgeOffset: CGFloat
    public var panelWidth: CGFloat
    public var panelHeight: CGFloat
    public var opacity: Double
    public var hoverOpenDelay: TimeInterval
    public var hoverCloseDelay: TimeInterval
    public var alwaysOnTop: Bool
    public var hideInFullscreen: Bool
    public var launchAtLogin: Bool
    public var appearance: AppearanceMode
    public var shape: EdgeItemShape
    public var itemSize: EdgeItemSize
    public var collapsedMode: CollapsedMode
    public var magnetRange: CGFloat
    public var showMenuBarIcon: Bool

    public init(
        selectedEdge: ScreenEdge = .right,
        edgeOffset: CGFloat = 120,
        panelWidth: CGFloat = LayoutMetrics.defaultPanelWidth,
        panelHeight: CGFloat = LayoutMetrics.defaultPanelHeight,
        opacity: Double = LayoutMetrics.defaultOpacity,
        hoverOpenDelay: TimeInterval = LayoutMetrics.defaultHoverOpenDelay,
        hoverCloseDelay: TimeInterval = LayoutMetrics.defaultHoverCloseDelay,
        alwaysOnTop: Bool = true,
        hideInFullscreen: Bool = false,
        launchAtLogin: Bool = false,
        appearance: AppearanceMode = .system,
        shape: EdgeItemShape = .circle,
        itemSize: EdgeItemSize = .medium,
        collapsedMode: CollapsedMode = .edgeTab,
        magnetRange: CGFloat = LayoutMetrics.magnetRange,
        showMenuBarIcon: Bool = true
    ) {
        self.selectedEdge = selectedEdge
        self.edgeOffset = edgeOffset
        self.panelWidth = panelWidth
        self.panelHeight = panelHeight
        self.opacity = min(max(opacity, LayoutMetrics.minimumOpacity), LayoutMetrics.maximumOpacity)
        self.hoverOpenDelay = hoverOpenDelay
        self.hoverCloseDelay = hoverCloseDelay
        self.alwaysOnTop = alwaysOnTop
        self.hideInFullscreen = hideInFullscreen
        self.launchAtLogin = launchAtLogin
        self.appearance = appearance
        self.shape = shape
        self.itemSize = itemSize
        self.collapsedMode = collapsedMode
        self.magnetRange = magnetRange
        self.showMenuBarIcon = showMenuBarIcon
    }

    public static let `default` = AppSettings()
}
