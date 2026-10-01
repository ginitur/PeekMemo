import Foundation
import PeekMemoCore

enum BackgroundPreferenceTests {
    static func run() throws {
        try defaultsAreSystemMaterial()
        try valuesSurviveANewStore()
        try opacitiesClamp()
        try unsafeFilenameIsDropped()
        try emptyFilenameLoadsAsNil()
        try unknownModesStayDefault()
        try resetClearsBackgroundAndKeepsLogin()
        try imageBytesAreNotStoredInDefaults()
    }

    static func defaultsAreSystemMaterial() throws {
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        let loaded = PreferencesStore(defaults: isolated.defaults).load()
        try expectEqual(loaded.backgroundMode, .systemMaterial)
        try expectEqual(loaded.backgroundSolidOpacity, 1)
        try expectEqual(loaded.backgroundImageFilename, nil)
        try expectEqual(loaded.backgroundImageContentMode, .fill)
        try expectEqual(loaded.backgroundImagePosition, .center)
        try expectEqual(loaded.backgroundImageOpacity, 0.60)
        try expectEqual(loaded.backgroundOverlayOpacity, 0.25)
        try expectEqual(loaded.panelOpacity, 0.94)
    }

    static func valuesSurviveANewStore() throws {
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        let written = AppearancePreferences(
            backgroundMode: .image,
            backgroundSolidColor: RGBAColor(red: 0.2, green: 0.3, blue: 0.4),
            backgroundSolidOpacity: 0.80,
            backgroundImageFilename: "background-AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE.jpg",
            backgroundImageContentMode: .fit,
            backgroundImagePosition: .bottom,
            backgroundImageOpacity: 0.40,
            backgroundOverlayOpacity: 0.55
        )
        PreferencesStore(defaults: isolated.defaults).save(written)
        let loaded = PreferencesStore(defaults: isolated.defaults).load()
        try expectEqual(loaded.backgroundMode, .image)
        try expectEqual(loaded.backgroundSolidOpacity, 0.80)
        try expectEqual(loaded.backgroundImageFilename, written.backgroundImageFilename)
        try expectEqual(loaded.backgroundImageContentMode, .fit)
        try expectEqual(loaded.backgroundImagePosition, .bottom)
        try expectEqual(loaded.backgroundImageOpacity, 0.40)
        try expectEqual(loaded.backgroundOverlayOpacity, 0.55)
        guard let parsed = RGBAColor.parse(hex: written.backgroundSolidColor.hex) else {
            throw CheckError(message: "solid color hex did not parse")
        }
        try expectEqual(loaded.backgroundSolidColor, parsed)
        let again = PreferencesStore(defaults: isolated.defaults).load()
        try expectEqual(again.backgroundImageFilename, loaded.backgroundImageFilename)
        try expectEqual(again.backgroundImageOpacity, loaded.backgroundImageOpacity)
    }

    static func opacitiesClamp() throws {
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        let store = PreferencesStore(defaults: isolated.defaults)
        store.save(AppearancePreferences(
            backgroundSolidOpacity: 0.05,
            backgroundImageOpacity: 5,
            backgroundOverlayOpacity: -0.2
        ))
        var loaded = store.load()
        try expectEqual(loaded.backgroundSolidOpacity, 0.40)
        try expectEqual(loaded.backgroundImageOpacity, 1)
        try expectEqual(loaded.backgroundOverlayOpacity, 0)
        store.save(AppearancePreferences(backgroundImageOpacity: 0.01, backgroundOverlayOpacity: 0.95))
        loaded = store.load()
        try expectEqual(loaded.backgroundImageOpacity, 0.20)
        try expectEqual(loaded.backgroundOverlayOpacity, 0.80)
    }

    static func unsafeFilenameIsDropped() throws {
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        let store = PreferencesStore(defaults: isolated.defaults)
        store.save(AppearancePreferences(
            backgroundMode: .image,
            backgroundImageFilename: "/Users/weijiaren/Downloads/photo.jpg"
        ))
        var loaded = store.load()
        try expectEqual(loaded.backgroundImageFilename, nil)
        try expect(isolated.defaults.object(forKey: PreferencesKey.backgroundImageFilename) is String)
        let stored = isolated.defaults.string(forKey: PreferencesKey.backgroundImageFilename) ?? "missing"
        try expect(!stored.contains("/"), "preferences stored a filesystem path")
        try expect(!(isolated.defaults.object(forKey: PreferencesKey.backgroundImageFilename) is Data))

        isolated.defaults.set("../secret.png", forKey: PreferencesKey.backgroundImageFilename)
        loaded = PreferencesStore(defaults: isolated.defaults).load()
        try expectEqual(loaded.backgroundImageFilename, nil)
    }

    static func emptyFilenameLoadsAsNil() throws {
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        isolated.defaults.set(PanelSizeMetrics.layoutMigrationVersion, forKey: PreferencesKey.layoutMigrationVersion)
        isolated.defaults.set("", forKey: PreferencesKey.backgroundImageFilename)
        let loaded = PreferencesStore(defaults: isolated.defaults).load()
        try expectEqual(loaded.backgroundImageFilename, nil)
        try expectEqual(loaded.backgroundMode, .systemMaterial)
    }

    static func unknownModesStayDefault() throws {
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        isolated.defaults.set(PanelSizeMetrics.layoutMigrationVersion, forKey: PreferencesKey.layoutMigrationVersion)
        isolated.defaults.set("video", forKey: PreferencesKey.backgroundMode)
        isolated.defaults.set("stretch", forKey: PreferencesKey.backgroundImageContentMode)
        isolated.defaults.set("left", forKey: PreferencesKey.backgroundImagePosition)
        let loaded = PreferencesStore(defaults: isolated.defaults).load()
        try expectEqual(loaded.backgroundMode, .systemMaterial)
        try expectEqual(loaded.backgroundImageContentMode, .fill)
        try expectEqual(loaded.backgroundImagePosition, .center)
    }

    static func resetClearsBackgroundAndKeepsLogin() throws {
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        let store = PreferencesStore(defaults: isolated.defaults)
        store.save(AppearancePreferences(
            backgroundMode: .image,
            backgroundImageFilename: "background-AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE.png",
            backgroundImageOpacity: 0.30,
            launchAtLogin: true
        ))
        store.resetAppearanceAndBehavior()
        try expect(isolated.defaults.object(forKey: PreferencesKey.backgroundMode) == nil)
        try expect(isolated.defaults.object(forKey: PreferencesKey.backgroundImageFilename) == nil)
        try expect(isolated.defaults.object(forKey: PreferencesKey.launchAtLogin) != nil)
        let loaded = store.load()
        try expectEqual(loaded.backgroundMode, .systemMaterial)
        try expectEqual(loaded.backgroundImageFilename, nil)
        try expectEqual(loaded.launchAtLogin, true)
        try expectEqual(loaded.panelWidth, 340)
        try expectEqual(loaded.panelHeight, 460)
    }

    static func imageBytesAreNotStoredInDefaults() throws {
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        let png = BackgroundImageFixtures.png
        PreferencesStore(defaults: isolated.defaults).save(AppearancePreferences(
            backgroundMode: .image,
            backgroundImageFilename: "background-AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE.png"
        ))
        for key in PreferencesKey.appearanceAndBehavior {
            let object = isolated.defaults.object(forKey: key)
            try expect(!(object is Data), "\(key) stored binary data")
        }
        let domain = isolated.defaults.dictionaryRepresentation()
        let blob = png.base64EncodedString()
        for (key, value) in domain where key.hasPrefix(PreferencesKey.prefix) {
            let text = String(describing: value)
            try expect(!text.contains(blob), "\(key) contains image bytes")
        }
    }
}
