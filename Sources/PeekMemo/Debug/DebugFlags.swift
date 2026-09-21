import Foundation
import PeekMemoCore

/// Debug-only overlays. Always false in Release.
@MainActor
enum DebugFlags {
    #if DEBUG
    static var showHitRegions = false
    static var showNotchGeometry = false
    static var showAnchorGeometry = false
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
    #endif
}
