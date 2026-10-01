import Foundation
import PeekMemoCore

enum EdgeRevealMotionTests {
    static func run() throws {
        try expect(LayoutMetrics.expandDuration >= 0.20 && LayoutMetrics.expandDuration <= 0.28)
        try expect(LayoutMetrics.collapseDuration >= 0.16 && LayoutMetrics.collapseDuration <= 0.22)
        try expect(LayoutMetrics.collapseDuration < LayoutMetrics.expandDuration)
        try expectEqual(RevealMotion.contentScale(opacity: 0, reduceMotion: false), 0.96)
        try expectEqual(RevealMotion.contentScale(opacity: 1, reduceMotion: false), 1)
        try expectEqual(RevealMotion.contentScale(opacity: 0, reduceMotion: true), 1)
        try expectEqual(RevealMotion.minimumScale, 0.96)
    }
}
