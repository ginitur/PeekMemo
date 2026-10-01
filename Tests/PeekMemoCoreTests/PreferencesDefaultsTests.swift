import Foundation
import PeekMemoCore

enum PreferencesDefaultsTests {
    static func run() throws {
        try missingKeysUseDefaults()
        try outOfRangeValuesClamp()
        try unknownEnumsStayDefault()
        try delaysSnapToChoices()
    }

    static func missingKeysUseDefaults() throws {
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        let loaded = PreferencesStore(defaults: isolated.defaults).load()
        try expectEqual(loaded, AppearancePreferences.default)
        try expectEqual(loaded.theme, .system)
        try expectEqual(loaded.panelOpacity, 0.94)
        try expectEqual(loaded.panelWidthPreset, .compact)
        try expectEqual(loaded.panelHeightPreset, .medium)
        try expectEqual(loaded.edgeTabThickness, LayoutMetrics.visibleTabThickness)
        try expectEqual(loaded.edgeTabLength, LayoutMetrics.defaultStackLength)
        try expectEqual(loaded.edgeTabColorMode, .systemAccent)
        try expectEqual(loaded.edgeTabOpacity, AppearancePreferences.defaultEdgeTabOpacity)
        try expectEqual(loaded.hoverOpenDelay, 0.16)
        try expectEqual(loaded.hoverCloseDelay, 0.35)
        try expectEqual(loaded.reduceMotion, false)
        try expectEqual(loaded.launchAtLogin, false)
        try expectEqual(loaded.hitRegionThickness, 14)
    }

    static func outOfRangeValuesClamp() throws {
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        let store = PreferencesStore(defaults: isolated.defaults)
        let wild = AppearancePreferences(
            panelOpacity: 0.2,
            edgeTabThickness: 9,
            edgeTabLength: 10,
            edgeTabOpacity: 0.01,
            hoverOpenDelay: 9,
            hoverCloseDelay: -1
        )
        store.save(wild)
        let loaded = PreferencesStore(defaults: isolated.defaults).load()
        try expectEqual(loaded.panelOpacity, 0.70)
        try expectEqual(loaded.edgeTabThickness, 6)
        try expectEqual(loaded.edgeTabLength, 32)
        try expectEqual(loaded.edgeTabOpacity, 0.20)
        try expectEqual(loaded.hoverOpenDelay, 0.40)
        try expectEqual(loaded.hoverCloseDelay, 0.15)
    }

    static func unknownEnumsStayDefault() throws {
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        isolated.defaults.set("neon", forKey: PreferencesKey.theme)
        isolated.defaults.set("pill", forKey: PreferencesKey.panelWidthPreset)
        isolated.defaults.set("huge", forKey: PreferencesKey.panelHeightPreset)
        isolated.defaults.set("glow", forKey: PreferencesKey.edgeTabColorMode)
        let loaded = PreferencesStore(defaults: isolated.defaults).load()
        try expectEqual(loaded.theme, .system)
        try expectEqual(loaded.panelWidthPreset, .compact)
        try expectEqual(loaded.panelHeightPreset, .medium)
        try expectEqual(loaded.edgeTabColorMode, .systemAccent)
    }

    static func delaysSnapToChoices() throws {
        let open = AppearancePreferences.nearest(0.12, in: AppearancePreferences.openDelayChoices)
        try expectEqual(open, 0.10)
        let tie = AppearancePreferences.nearest(0.13, in: AppearancePreferences.openDelayChoices)
        try expectEqual(tie, 0.10)
        let close = AppearancePreferences.nearest(0.99, in: AppearancePreferences.closeDelayChoices)
        try expectEqual(close, 0.75)
        try expect(AppearancePreferences.openDelayChoices.contains(0))
        try expect(AppearancePreferences.openDelayChoices.contains(0.16))
        try expect(AppearancePreferences.closeDelayChoices.contains(0.35))
    }
}
