import CoreGraphics
import Foundation

/// Platform-agnostic snapshot of a display. Built from `NSScreen` on macOS.
public struct ScreenGeometry: Equatable, Sendable {
    public var identifier: String
    public var frame: CGRect
    public var visibleFrame: CGRect

    public init(
        identifier: String,
        frame: CGRect,
        visibleFrame: CGRect
    ) {
        self.identifier = identifier
        self.frame = frame
        self.visibleFrame = visibleFrame
    }
}

public struct PanelPlacement: Equatable, Sendable {
    public var displayIdentifier: String
    public var edge: ScreenEdge
    public var offset: CGFloat
    public var frame: CGRect
    public var isSnapped: Bool

    public init(
        displayIdentifier: String,
        edge: ScreenEdge,
        offset: CGFloat,
        frame: CGRect,
        isSnapped: Bool = true
    ) {
        self.displayIdentifier = displayIdentifier
        self.edge = edge
        self.offset = offset
        self.frame = frame
        self.isSnapped = isSnapped
    }

    public var stored: DisplayPlacement {
        DisplayPlacement(
            displayIdentifier: displayIdentifier,
            edge: edge,
            offset: offset
        )
    }
}
