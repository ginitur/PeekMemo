import PeekMemoCore
import SwiftUI

/// Content fade and scale for one expand or collapse. Idle panels do not animate.
@MainActor
final class RevealChrome: ObservableObject {
    @Published var opacity: Double = 1
    @Published var reduceMotion = false
    @Published var animates = true
    @Published var collapsing = false

    var animation: Animation? {
        guard animates else { return nil }
        if reduceMotion {
            return .easeOut(duration: 0.08)
        }
        if collapsing {
            return .easeOut(duration: 0.12)
        }
        return .spring(response: LayoutMetrics.expandDuration, dampingFraction: 0.86)
    }
}
