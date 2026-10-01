import Foundation
import PeekMemoCore

enum HoverDelayPreferenceTests {
    static func run() throws {
        try defaultsMatchTheEngine()
        try storedDelaysSurviveANewStore()
        try engineSchedulesTheAssignedDelay()
        try unknownDelaySnapsBeforeItIsSaved()
    }

    static func defaultsMatchTheEngine() throws {
        let prefs = AppearancePreferences.default
        let engine = HoverEngine()
        try expectEqual(prefs.hoverOpenDelay, engine.openDelay)
        try expectEqual(prefs.hoverCloseDelay, engine.closeDelay)
        try expectEqual(prefs.hoverOpenDelay, 0.16)
        try expectEqual(prefs.hoverCloseDelay, 0.35)
    }

    static func storedDelaysSurviveANewStore() throws {
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        var prefs = AppearancePreferences.default
        prefs.hoverOpenDelay = 0
        prefs.hoverCloseDelay = 0.50
        PreferencesStore(defaults: isolated.defaults).save(prefs)
        let loaded = PreferencesStore(defaults: isolated.defaults).load()
        try expectEqual(loaded.hoverOpenDelay, 0)
        try expectEqual(loaded.hoverCloseDelay, 0.50)
        try expect(AppearancePreferences.openDelayChoices.contains(loaded.hoverOpenDelay))
        try expect(AppearancePreferences.closeDelayChoices.contains(loaded.hoverCloseDelay))
    }

    static func engineSchedulesTheAssignedDelay() throws {
        var engine = HoverEngine()
        engine.openDelay = 0.25
        engine.closeDelay = 0.75
        let open = engine.handle(.pointerEnteredRegion)
        try expectEqual(open, .scheduleOpen(0.25))
        _ = engine.handle(.openDelayElapsed)
        let close = engine.handle(.pointerExitedRegion)
        try expectEqual(close, .scheduleClose(0.75))
    }

    static func unknownDelaySnapsBeforeItIsSaved() throws {
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        let prefs = AppearancePreferences(hoverOpenDelay: 0.12, hoverCloseDelay: 0.30)
        PreferencesStore(defaults: isolated.defaults).save(prefs)
        let loaded = PreferencesStore(defaults: isolated.defaults).load()
        try expectEqual(loaded.hoverOpenDelay, 0.10)
        try expectEqual(loaded.hoverCloseDelay, 0.25)
    }
}
