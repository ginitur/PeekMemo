import CoreGraphics
import Foundation

public struct EdgeInsetsLTRB: Equatable, Sendable, Codable {
    public var top: CGFloat
    public var left: CGFloat
    public var bottom: CGFloat
    public var right: CGFloat

    public init(top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }

    public static let zero = EdgeInsetsLTRB()
}

/// Platform-agnostic snapshot of a display. Built from `NSScreen` on macOS.
public struct ScreenGeometry: Equatable, Sendable {
    public var identifier: String
    public var frame: CGRect
    public var visibleFrame: CGRect
    public var safeAreaInsets: EdgeInsetsLTRB
    public var auxiliaryTopLeft: CGRect?
    public var auxiliaryTopRight: CGRect?

    public init(
        identifier: String,
        frame: CGRect,
        visibleFrame: CGRect,
        safeAreaInsets: EdgeInsetsLTRB = .zero,
        auxiliaryTopLeft: CGRect? = nil,
        auxiliaryTopRight: CGRect? = nil
    ) {
        self.identifier = identifier
        self.frame = frame
        self.visibleFrame = visibleFrame
        self.safeAreaInsets = safeAreaInsets
        self.auxiliaryTopLeft = auxiliaryTopLeft
        self.auxiliaryTopRight = auxiliaryTopRight
    }

    public var hasNotch: Bool {
        NotchGeometry.region(on: self) != nil
    }
}

public struct NotchRegion: Equatable, Sendable {
    public var frame: CGRect

    public init(frame: CGRect) {
        self.frame = frame
    }
}

public struct PanelPlacement: Equatable, Sendable {
    public var displayIdentifier: String
    public var edge: ScreenEdge
    public var offset: CGFloat
    public var frame: CGRect
    public var isNotchCloak: Bool
    public var isSnapped: Bool

    public init(
        displayIdentifier: String,
        edge: ScreenEdge,
        offset: CGFloat,
        frame: CGRect,
        isNotchCloak: Bool = false,
        isSnapped: Bool = true
    ) {
        self.displayIdentifier = displayIdentifier
        self.edge = edge
        self.offset = offset
        self.frame = frame
        self.isNotchCloak = isNotchCloak
        self.isSnapped = isSnapped
    }

    public var stored: DisplayPlacement {
        DisplayPlacement(
            displayIdentifier: displayIdentifier,
            edge: edge,
            offset: offset,
            isNotchCloak: isNotchCloak
        )
    }
}
