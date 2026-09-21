import Foundation

public enum HoverPhase: String, Sendable, Equatable {
    case collapsed
    case hovering
    case expanded
    case pinned
    case editing
}

public enum HoverInput: Sendable, Equatable {
    case pointerEnteredRegion
    case pointerExitedRegion
    case openDelayElapsed
    case closeDelayElapsed
    case click
    case doubleClick
    case endEditing
}

public enum HoverOutput: Sendable, Equatable {
    case none
    case scheduleOpen(TimeInterval)
    case scheduleClose(TimeInterval)
    case cancelTimers
    case expand
    case collapse
    case beginEditing
}

/// Pure hover state machine. AppKit supplies events; this type does not read `NSEvent`.
public struct HoverEngine: Equatable, Sendable {
    public private(set) var phase: HoverPhase
    public var openDelay: TimeInterval
    public var closeDelay: TimeInterval

    public init(
        phase: HoverPhase = .collapsed,
        openDelay: TimeInterval = LayoutMetrics.defaultHoverOpenDelay,
        closeDelay: TimeInterval = LayoutMetrics.defaultHoverCloseDelay
    ) {
        self.phase = phase
        self.openDelay = openDelay
        self.closeDelay = closeDelay
    }

    public var isVisuallyExpanded: Bool {
        switch phase {
        case .expanded, .pinned, .editing: true
        case .collapsed, .hovering: false
        }
    }

    public var allowsKeyWindow: Bool {
        phase == .editing
    }

    @discardableResult
    public mutating func handle(_ input: HoverInput) -> HoverOutput {
        switch (phase, input) {
        case (.collapsed, .pointerEnteredRegion):
            phase = .hovering
            return .scheduleOpen(openDelay)

        case (.hovering, .pointerExitedRegion):
            phase = .collapsed
            return .cancelTimers

        case (.hovering, .openDelayElapsed):
            phase = .expanded
            return .expand

        case (.hovering, .click):
            phase = .pinned
            return .expand

        case (.hovering, .doubleClick):
            phase = .editing
            return .beginEditing

        case (.expanded, .pointerExitedRegion):
            return .scheduleClose(closeDelay)

        case (.expanded, .pointerEnteredRegion):
            return .cancelTimers

        case (.expanded, .closeDelayElapsed):
            phase = .collapsed
            return .collapse

        case (.expanded, .click):
            phase = .pinned
            return .cancelTimers

        case (.expanded, .doubleClick):
            phase = .editing
            return .beginEditing

        case (.pinned, .click):
            phase = .expanded
            return .none

        case (.pinned, .doubleClick):
            phase = .editing
            return .beginEditing

        case (.pinned, .pointerEnteredRegion), (.pinned, .pointerExitedRegion):
            return .none

        case (.editing, .endEditing):
            phase = .pinned
            return .none

        case (.editing, _):
            return .none

        case (.collapsed, .click):
            phase = .pinned
            return .expand

        case (.collapsed, .doubleClick):
            phase = .editing
            return .beginEditing

        default:
            return .none
        }
    }
}
