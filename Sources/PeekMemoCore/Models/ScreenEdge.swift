import Foundation

public enum ScreenEdge: String, Codable, Sendable, CaseIterable, Equatable {
    case left
    case right
    case top
    case bottom

    /// Direction the expanded panel grows, toward the interior of the screen.
    public var expansion: ExpansionDirection {
        switch self {
        case .left: .right
        case .right: .left
        case .top: .down
        case .bottom: .up
        }
    }

    public var isVertical: Bool {
        self == .left || self == .right
    }
}

public enum ExpansionDirection: String, Sendable, Equatable {
    case left
    case right
    case up
    case down
}
