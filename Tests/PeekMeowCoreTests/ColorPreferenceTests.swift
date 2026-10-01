import Foundation
import PeekMeowCore

enum ColorPreferenceTests {
    static func run() throws {
        try customColorRoundTripsAsHex()
        try invalidHexFallsBack()
        try alphaIsQuantizedThroughHex()
        try hoverRaisesOpacityWithoutExceedingOne()
        try colorIsNotArchivedAsData()
    }

    static func customColorRoundTripsAsHex() throws {
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        var prefs = AppearancePreferences.default
        prefs.edgeTabColorMode = .custom
        prefs.edgeTabCustomColor = RGBAColor(red: 1, green: 0.5, blue: 0, alpha: 1)
        PreferencesStore(defaults: isolated.defaults).save(prefs)
        let loaded = PreferencesStore(defaults: isolated.defaults).load()
        try expectEqual(loaded.edgeTabColorMode, .custom)
        try expectEqual(loaded.edgeTabCustomColor.hex, "#FF8000")
        try expectEqual(loaded.edgeTabCustomColor, RGBAColor.parse(hex: "#FF8000") ?? .accent)
    }

    static func invalidHexFallsBack() throws {
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        isolated.defaults.set("not-a-color", forKey: PreferencesKey.edgeTabCustomColor)
        isolated.defaults.set(EdgeTabColorMode.custom.rawValue, forKey: PreferencesKey.edgeTabColorMode)
        let loaded = PreferencesStore(defaults: isolated.defaults).load()
        try expectEqual(loaded.edgeTabColorMode, .custom)
        try expectEqual(loaded.edgeTabCustomColor, AppearancePreferences.default.edgeTabCustomColor)
    }

    static func alphaIsQuantizedThroughHex() throws {
        let original = RGBAColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 0.4)
        guard let parsed = RGBAColor.parse(hex: original.hex) else {
            throw CheckError(message: "alpha color hex did not parse")
        }
        try expect(original.hex.count == 9, original.hex)
        try expectEqual(parsed, RGBAColor.parse(hex: original.hex) ?? parsed)
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        var prefs = AppearancePreferences.default
        prefs.edgeTabCustomColor = original
        PreferencesStore(defaults: isolated.defaults).save(prefs)
        let loaded = PreferencesStore(defaults: isolated.defaults).load()
        try expectEqual(loaded.edgeTabCustomColor, parsed)
    }

    static func hoverRaisesOpacityWithoutExceedingOne() throws {
        let quiet = AppearancePreferences.displayedEdgeTabOpacity(base: 0.55, emphasized: false)
        try expect(abs(quiet - 0.55) < 0.001, "\(quiet)")
        let raised = AppearancePreferences.displayedEdgeTabOpacity(base: 0.55, emphasized: true)
        try expect(abs(raised - 0.73) < 0.001, "\(raised)")
        let capped = AppearancePreferences.displayedEdgeTabOpacity(base: 0.90, emphasized: true)
        try expectEqual(capped, 1)
    }

    static func colorIsNotArchivedAsData() throws {
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        PreferencesStore(defaults: isolated.defaults).save(PreferencesTestSupport.changed())
        let stored = isolated.defaults.object(forKey: PreferencesKey.edgeTabCustomColor)
        try expect(stored is String, "color must be hex text, not archived data")
        try expect(!(stored is Data))
    }
}
