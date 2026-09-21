import Foundation

/// Debug-only overlays. Always false in Release.
@MainActor
enum DebugFlags {
    #if DEBUG
    static var showHitRegions = false
    static var showNotchGeometry = false
    #else
    static let showHitRegions = false
    static let showNotchGeometry = false
    #endif
}
