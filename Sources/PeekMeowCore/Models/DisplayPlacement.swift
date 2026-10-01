import CoreGraphics
import Foundation

/// Per-display edge placement. Absolute x/y is derived, never stored as source of truth.
public struct DisplayPlacement: Equatable, Sendable, Codable {
    public var displayIdentifier: String
    public var edge: ScreenEdge
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
}
