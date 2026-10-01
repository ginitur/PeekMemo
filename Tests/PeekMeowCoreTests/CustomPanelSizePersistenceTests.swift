import Foundation
import PeekMeowCore

enum CustomPanelSizePersistenceTests {
    static func run() throws {
        try customSizeSurvivesANewStore()
        try presetSelectionStoresItsCard()
        try storedSizeIsNotClampedToASmallScreen()
    }

    static func customSizeSurvivesANewStore() throws {
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        let written = AppearancePreferences(panelSizeMode: .custom, panelWidth: 368, panelHeight: 512)
        PreferencesStore(defaults: isolated.defaults).save(written)
        let loaded = PreferencesStore(defaults: isolated.defaults).load()
        try expectEqual(loaded.panelSizeMode, .custom)
        try expectEqual(loaded.panelWidth, 368)
        try expectEqual(loaded.panelHeight, 512)
        try expectEqual(loaded.sizeLabel, "368 × 512")
    }

    static func presetSelectionStoresItsCard() throws {
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        PreferencesStore(defaults: isolated.defaults).save(AppearancePreferences(panelSizeMode: .small))
        let loaded = PreferencesStore(defaults: isolated.defaults).load()
        try expectEqual(loaded.panelSizeMode, .small)
        try expectEqual(loaded.panelWidth, 300)
        try expectEqual(loaded.panelHeight, 360)
    }

    static func storedSizeIsNotClampedToASmallScreen() throws {
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        PreferencesStore(defaults: isolated.defaults).save(AppearancePreferences(panelSizeMode: .large))
        let loaded = PreferencesStore(defaults: isolated.defaults).load()
        let visible = CGSize(width: 360, height: 400)
        let display = loaded.displayContentSize(visible: visible, edgeIsVertical: true)
        try expect(display.width < loaded.panelWidth)
        try expect(display.height < loaded.panelHeight)
        let again = PreferencesStore(defaults: isolated.defaults).load()
        try expectEqual(again.panelWidth, 420)
        try expectEqual(again.panelHeight, 560)
    }
}
