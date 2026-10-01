import Foundation
import PeekMeowCore

enum PreferencesPersistenceTests {
    static func run() throws {
        try valuesSurviveANewStore()
        try everyKeyRoundTrips()
    }

    static func valuesSurviveANewStore() throws {
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        let written = PreferencesTestSupport.changed()
        PreferencesStore(defaults: isolated.defaults).save(written)
        let loaded = PreferencesStore(defaults: isolated.defaults).load()
        try expectEqual(loaded.theme, written.theme)
        try expectEqual(loaded.panelOpacity, written.panelOpacity)
        try expectEqual(loaded.panelSizeMode, written.panelSizeMode)
        try expectEqual(loaded.panelWidth, written.panelWidth)
        try expectEqual(loaded.panelHeight, written.panelHeight)
        try expectEqual(loaded.edgeTabThickness, written.edgeTabThickness)
        try expectEqual(loaded.edgeTabLength, written.edgeTabLength)
        try expectEqual(loaded.edgeTabColorMode, written.edgeTabColorMode)
        try expectEqual(loaded.edgeTabOpacity, written.edgeTabOpacity)
        try expectEqual(loaded.hoverOpenDelay, written.hoverOpenDelay)
        try expectEqual(loaded.hoverCloseDelay, written.hoverCloseDelay)
        try expectEqual(loaded.reduceMotion, written.reduceMotion)
        try expectEqual(loaded.launchAtLogin, written.launchAtLogin)
        guard let parsed = RGBAColor.parse(hex: written.edgeTabCustomColor.hex) else {
            throw CheckError(message: "custom color hex did not parse")
        }
        try expectEqual(loaded.edgeTabCustomColor, parsed)
    }

    static func everyKeyRoundTrips() throws {
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        PreferencesStore(defaults: isolated.defaults).save(PreferencesTestSupport.changed())
        let keys = PreferencesKey.appearanceAndBehavior + [PreferencesKey.launchAtLogin]
        for key in keys {
            try expect(isolated.defaults.object(forKey: key) != nil, "missing \(key)")
        }
        try expect(isolated.defaults.object(forKey: PreferencesKey.edgeTabCustomColor) is String)
    }
}
