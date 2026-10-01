import CoreGraphics
import Foundation

/// Stable placement on one display edge. Only a user drag may change `offset`.
public struct EdgeAnchor: Equatable, Sendable, Codable {
    public var displayIdentifier: String
    public var edge: ScreenEdge
    /// Distance along the edge from the start of `visibleFrame` to the handle center.
    /// Left/Right: from the top of `visibleFrame` downward.
    /// Top/Bottom: from `visibleFrame.minX` rightward.
    public var offset: CGFloat

    public init(
        displayIdentifier: String,
        edge: ScreenEdge,
        offset: CGFloat
    ) {
        self.displayIdentifier = displayIdentifier
        self.edge = edge
        self.offset = offset
    }

    public var asPlacement: DisplayPlacement {
        DisplayPlacement(
            displayIdentifier: displayIdentifier,
            edge: edge,
            offset: offset
        )
    }

    public static func from(_ placement: DisplayPlacement) -> EdgeAnchor {
        EdgeAnchor(
            displayIdentifier: placement.displayIdentifier,
            edge: placement.edge,
            offset: placement.offset
        )
    }
}

/// Result of expanding around a fixed `EdgeAnchor`.
public struct ExpansionLayout: Equatable, Sendable {
    public var panelFrame: CGRect
    public var collapsedFrame: CGRect
    public var anchorPoint: CGPoint
    public var handleAttachmentPoint: CGPoint
    /// Distance from the panel’s leading inner origin to the handle center.
    /// Vertical edges: from `panelFrame.maxY` downward. Horizontal edges: from `panelFrame.minX` rightward.
    public var handleOffsetInsidePanel: CGFloat
    public var offset: CGFloat
    public var wasClamped: Bool

    public init(
        panelFrame: CGRect,
        collapsedFrame: CGRect,
        anchorPoint: CGPoint,
        handleAttachmentPoint: CGPoint,
        handleOffsetInsidePanel: CGFloat,
        offset: CGFloat,
        wasClamped: Bool
    ) {
        self.panelFrame = panelFrame
        self.collapsedFrame = collapsedFrame
        self.anchorPoint = anchorPoint
        self.handleAttachmentPoint = handleAttachmentPoint
        self.handleOffsetInsidePanel = handleOffsetInsidePanel
        self.offset = offset
        self.wasClamped = wasClamped
    }
}
