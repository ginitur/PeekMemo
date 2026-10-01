import Foundation
import PeekMeowCore

enum ReduceMotionPreferenceTests {
    static func run() throws {
        try eitherSourceReducesMovement()
        try movementBecomesInstant()
        try contentFadeStays()
        try preferenceRoundTrips()
    }

    static func eitherSourceReducesMovement() throws {
        try expectEqual(MotionPolicy.shouldReduce(preference: false, systemEnabled: false), false)
        try expectEqual(MotionPolicy.shouldReduce(preference: true, systemEnabled: false), true)
        try expectEqual(MotionPolicy.shouldReduce(preference: false, systemEnabled: true), true)
        try expectEqual(MotionPolicy.shouldReduce(preference: true, systemEnabled: true), true)
    }

    static func movementBecomesInstant() throws {
        try expectEqual(MotionPolicy.movementDuration(LayoutMetrics.expandDuration, reduce: true), 0)
        try expectEqual(MotionPolicy.movementDuration(LayoutMetrics.collapseDuration, reduce: true), 0)
        try expectEqual(
            MotionPolicy.movementDuration(LayoutMetrics.expandDuration, reduce: false),
            LayoutMetrics.expandDuration
        )
        try expectEqual(
            MotionPolicy.movementDuration(LayoutMetrics.collapseDuration, reduce: false),
            LayoutMetrics.collapseDuration
        )
    }

    static func contentFadeStays() throws {
        try expect(LayoutMetrics.contentFadeDelay > 0)
        try expect(LayoutMetrics.contentFadeOutDuration > 0)
        try expect(LayoutMetrics.contentFadeDelay < LayoutMetrics.expandDuration)
    }

    static func preferenceRoundTrips() throws {
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        var prefs = AppearancePreferences.default
        prefs.reduceMotion = true
        PreferencesStore(defaults: isolated.defaults).save(prefs)
        let loaded = PreferencesStore(defaults: isolated.defaults).load()
        try expectEqual(loaded.reduceMotion, true)
        try expectEqual(
            MotionPolicy.shouldReduce(preference: loaded.reduceMotion, systemEnabled: false),
            true
        )
    }
}
