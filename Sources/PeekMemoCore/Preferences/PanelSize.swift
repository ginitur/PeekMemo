import CoreGraphics
import Foundation

/// Quick size choices. A drag sets `.custom` and stores the exact width and height.
public enum PanelSizeMode: String, Codable, Sendable, CaseIterable {
    case small
    case medium
    case large
    case custom
}

/// Memo-card size in points. The 14 pt hit rail is added outside this on the contact edge.
public struct PanelContentSize: Equatable, Sendable {
    public var width: CGFloat
    public var height: CGFloat

    public init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
    }
}

/// Phase 7 width choices. Read only while migrating old preferences.
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

/// Phase 7 maximum-height choices. Read only while migrating old preferences.
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

public enum PanelSizeMetrics: Sendable {
    public static let layoutMigrationVersion = 1
    public static let minimumWidth: CGFloat = 280
    public static let minimumHeight: CGFloat = 300
    public static let defaultWidth: CGFloat = 340
    public static let defaultHeight: CGFloat = 460
    /// Stored sizes above this are clamped. The live window is also clamped to the screen.
    public static let absoluteMaximum: CGFloat = 2400
    public static let cornerRadius: CGFloat = 16

    public static let small = PanelContentSize(width: 300, height: 360)
    public static let medium = PanelContentSize(width: defaultWidth, height: defaultHeight)
    public static let large = PanelContentSize(width: 420, height: 560)

    public static func preset(_ mode: PanelSizeMode) -> PanelContentSize {
        switch mode {
        case .small: small
        case .medium, .custom: medium
        case .large: large
        }
    }

    /// Keeps a saved size inside the absolute range. Does not look at the screen.
    public static func clampStored(_ size: PanelContentSize) -> PanelContentSize {
        PanelContentSize(
            width: min(max(size.width, minimumWidth), absoluteMaximum),
            height: min(max(size.height, minimumHeight), absoluteMaximum)
        )
    }

    /// Fits the card on this display without writing the smaller size back.
    /// A screen smaller than the minimum wins, so the window cannot leave `visibleFrame`.
    public static func clampToScreen(
        _ size: PanelContentSize,
        visible: CGSize,
        edgeIsVertical: Bool
    ) -> PanelContentSize {
        let hit = LayoutMetrics.hoverHitThickness
        let maxWidth = edgeIsVertical ? visible.width - hit : visible.width
        let maxHeight = edgeIsVertical ? visible.height : visible.height - hit
        let lowerWidth = min(minimumWidth, max(0, maxWidth))
        let lowerHeight = min(minimumHeight, max(0, maxHeight))
        return PanelContentSize(
            width: min(max(size.width, lowerWidth), max(lowerWidth, maxWidth)),
            height: min(max(size.height, lowerHeight), max(lowerHeight, maxHeight))
        )
    }

    public static func windowSize(content: PanelContentSize, edgeIsVertical: Bool) -> CGSize {
        let hit = LayoutMetrics.hoverHitThickness
        if edgeIsVertical {
            return CGSize(width: content.width + hit, height: content.height)
        }
        return CGSize(width: content.width, height: content.height + hit)
    }
}

public enum PanelSizeMigration: Sendable {
    public struct Result: Equatable, Sendable {
        public var mode: PanelSizeMode
        public var width: CGFloat
        public var height: CGFloat

        public init(mode: PanelSizeMode, width: CGFloat, height: CGFloat) {
            self.mode = mode
            self.width = width
            self.height = height
        }
    }

    /// Maps a Phase 7 preset pair once. The old default (compact + medium) becomes 340×460,
    /// not the old short content height. A non-default pair keeps its width and height intent.
    public static func map(
        widthPreset: PanelWidthPreset?,
        heightPreset: PanelHeightPreset?
    ) -> Result {
        guard widthPreset != nil || heightPreset != nil else {
            return Result(mode: .medium, width: PanelSizeMetrics.defaultWidth, height: PanelSizeMetrics.defaultHeight)
        }
        let width = widthPreset ?? .compact
        let height = heightPreset ?? .medium
        if width == .compact, height == .medium {
            return Result(mode: .medium, width: PanelSizeMetrics.defaultWidth, height: PanelSizeMetrics.defaultHeight)
        }
        let mappedWidth: CGFloat = switch width {
        case .compact: PanelSizeMetrics.small.width
        case .medium: PanelSizeMetrics.medium.width
        case .wide: PanelSizeMetrics.large.width
        }
        let mappedHeight: CGFloat = switch height {
        case .small: PanelSizeMetrics.small.height
        case .medium: PanelSizeMetrics.medium.height
        case .large: PanelSizeMetrics.large.height
        }
        return Result(
            mode: mode(width: mappedWidth, height: mappedHeight),
            width: mappedWidth,
            height: mappedHeight
        )
    }

    public static func mode(width: CGFloat, height: CGFloat) -> PanelSizeMode {
        if abs(width - PanelSizeMetrics.small.width) < 0.5,
           abs(height - PanelSizeMetrics.small.height) < 0.5 {
            return .small
        }
        if abs(width - PanelSizeMetrics.medium.width) < 0.5,
           abs(height - PanelSizeMetrics.medium.height) < 0.5 {
            return .medium
        }
        if abs(width - PanelSizeMetrics.large.width) < 0.5,
           abs(height - PanelSizeMetrics.large.height) < 0.5 {
            return .large
        }
        return .custom
    }
}
