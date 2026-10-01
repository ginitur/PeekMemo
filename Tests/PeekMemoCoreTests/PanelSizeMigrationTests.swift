import Foundation
import PeekMemoCore

enum PanelSizeMigrationTests {
    static func run() throws {
        try freshInstallUsesTheTallDefault()
        try oldDefaultDoesNotStayShort()
        try explicitPresetsKeepTheirIntent()
        try migrationRunsOnce()
        try resetDoesNotReapplyTheOldPreset()
    }

    static func freshInstallUsesTheTallDefault() throws {
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        let loaded = PreferencesStore(defaults: isolated.defaults).load()
        try expectEqual(loaded.panelSizeMode, .medium)
        try expectEqual(loaded.panelWidth, 340)
        try expectEqual(loaded.panelHeight, 460)
        try expectEqual(
            isolated.defaults.integer(forKey: PreferencesKey.layoutMigrationVersion),
            PanelSizeMetrics.layoutMigrationVersion
        )
    }

    static func oldDefaultDoesNotStayShort() throws {
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        isolated.defaults.set(PanelWidthPreset.compact.rawValue, forKey: PreferencesKey.panelWidthPreset)
        isolated.defaults.set(PanelHeightPreset.medium.rawValue, forKey: PreferencesKey.panelHeightPreset)
        let loaded = PreferencesStore(defaults: isolated.defaults).load()
        try expectEqual(loaded.panelSizeMode, .medium)
        try expectEqual(loaded.panelWidth, 340)
        try expectEqual(loaded.panelHeight, 460)
        try expect(loaded.panelHeight > 120)
    }

    static func explicitPresetsKeepTheirIntent() throws {
        try expectEqual(
            PanelSizeMigration.map(widthPreset: .compact, heightPreset: .small),
            PanelSizeMigration.Result(mode: .small, width: 300, height: 360)
        )
        try expectEqual(
            PanelSizeMigration.map(widthPreset: .wide, heightPreset: .large),
            PanelSizeMigration.Result(mode: .large, width: 420, height: 560)
        )
        try expectEqual(
            PanelSizeMigration.map(widthPreset: .wide, heightPreset: .medium),
            PanelSizeMigration.Result(mode: .custom, width: 420, height: 460)
        )
        try expectEqual(
            PanelSizeMigration.map(widthPreset: .compact, heightPreset: .large),
            PanelSizeMigration.Result(mode: .custom, width: 300, height: 560)
        )

        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        isolated.defaults.set(PanelWidthPreset.wide.rawValue, forKey: PreferencesKey.panelWidthPreset)
        isolated.defaults.set(PanelHeightPreset.small.rawValue, forKey: PreferencesKey.panelHeightPreset)
        let loaded = PreferencesStore(defaults: isolated.defaults).load()
        try expectEqual(loaded.panelSizeMode, .custom)
        try expectEqual(loaded.panelWidth, 420)
        try expectEqual(loaded.panelHeight, 360)
    }

    static func migrationRunsOnce() throws {
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        isolated.defaults.set(PanelWidthPreset.compact.rawValue, forKey: PreferencesKey.panelWidthPreset)
        isolated.defaults.set(PanelHeightPreset.medium.rawValue, forKey: PreferencesKey.panelHeightPreset)
        let store = PreferencesStore(defaults: isolated.defaults)
        _ = store.load()
        var resized = store.load()
        resized.panelSizeMode = .custom
        resized.panelWidth = 368
        resized.panelHeight = 512
        store.save(resized)
        let again = PreferencesStore(defaults: isolated.defaults).load()
        try expectEqual(again.panelSizeMode, .custom)
        try expectEqual(again.panelWidth, 368)
        try expectEqual(again.panelHeight, 512)
    }

    static func resetDoesNotReapplyTheOldPreset() throws {
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        isolated.defaults.set(PanelWidthPreset.compact.rawValue, forKey: PreferencesKey.panelWidthPreset)
        isolated.defaults.set(PanelHeightPreset.large.rawValue, forKey: PreferencesKey.panelHeightPreset)
        let store = PreferencesStore(defaults: isolated.defaults)
        let migrated = store.load()
        try expectEqual(migrated.panelWidth, 300)
        try expectEqual(migrated.panelHeight, 560)
        store.resetAppearanceAndBehavior()
        let reset = PreferencesStore(defaults: isolated.defaults).load()
        try expectEqual(reset.panelSizeMode, .medium)
        try expectEqual(reset.panelWidth, 340)
        try expectEqual(reset.panelHeight, 460)
        try expectEqual(
            isolated.defaults.integer(forKey: PreferencesKey.layoutMigrationVersion),
            PanelSizeMetrics.layoutMigrationVersion
        )
    }
}
