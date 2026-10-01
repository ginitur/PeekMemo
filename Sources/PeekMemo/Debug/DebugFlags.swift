import Foundation
import PeekMemoCore

#if DEBUG
struct InteractionLogKey: Equatable {
    var hoverState: HoverPhase
    var editingItemID: UUID?
    var isComposing: Bool
    var isKeyWindow: Bool
    var allowsKey: Bool
    var isPinned: Bool
    var interactionHoldCount: Int
    var mouseInsideEdge: Bool
    var mouseInsidePanel: Bool
    var insideEditor: Bool
}
#endif

/// Debug-only overlays. Always false in Release.
@MainActor
enum DebugFlags {
    #if DEBUG
    static var showHitRegions = false
    static var showAnchorGeometry = false
    static var showInteractionRegions = false
    #else
    static let showHitRegions = false
    static let showAnchorGeometry = false
    static let showInteractionRegions = false
    #endif
}
