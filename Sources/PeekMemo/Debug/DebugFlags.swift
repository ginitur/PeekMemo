import Foundation

/// Debug-only overlays. Always false in Release.
@MainActor
enum DebugFlags {
    #if DEBUG
    static var showHitRegions = false
    #else
    static let showHitRegions = false
    #endif
}
