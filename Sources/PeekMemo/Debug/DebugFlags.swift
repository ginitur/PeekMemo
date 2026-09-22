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
    static var showNotchGeometry = false
    static var showAnchorGeometry = false
    static var showInteractionRegions = false
    static var experimentalTopEdge = false {
        didSet {
            PlacementPolicy.allowTopEdgeSnap = experimentalTopEdge
            PlacementPolicy.allowNotchCloak = experimentalTopEdge
        }
    }
    #else
    static let showHitRegions = false
    static let showNotchGeometry = false
    static let showAnchorGeometry = false
    static let showInteractionRegions = false
    #endif
}
