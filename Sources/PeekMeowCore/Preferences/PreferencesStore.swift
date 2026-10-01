import Foundation

/// Every appearance UserDefaults key. Views must not write these themselves.
public enum PreferencesKey {
    public static let prefix = "peekmeow.preferences."
    public static let theme = prefix + "theme"
    public static let panelOpacity = prefix + "panelOpacity"
    public static let panelWidthPreset = prefix + "panelWidthPreset"
    public static let panelHeightPreset = prefix + "panelHeightPreset"
    public static let panelSizeMode = prefix + "panelSizeMode"
    public static let panelWidth = prefix + "panelWidth"
    public static let panelHeight = prefix + "panelHeight"
    public static let layoutMigrationVersion = prefix + "layoutMigrationVersion"
    public static let backgroundMode = prefix + "backgroundMode"
    public static let backgroundSolidColor = prefix + "backgroundSolidColor"
    public static let backgroundSolidOpacity = prefix + "backgroundSolidOpacity"
    public static let backgroundImageFilename = prefix + "backgroundImageFilename"
    public static let backgroundImageContentMode = prefix + "backgroundImageContentMode"
    public static let backgroundImagePosition = prefix + "backgroundImagePosition"
    public static let backgroundImageOpacity = prefix + "backgroundImageOpacity"
    public static let backgroundOverlayOpacity = prefix + "backgroundOverlayOpacity"
    public static let edgeTabThickness = prefix + "edgeTabThickness"
    public static let edgeTabLength = prefix + "edgeTabLength"
    public static let edgeTabColorMode = prefix + "edgeTabColorMode"
    public static let edgeTabCustomColor = prefix + "edgeTabCustomColor"
    public static let edgeTabOpacity = prefix + "edgeTabOpacity"
    public static let hoverOpenDelay = prefix + "hoverOpenDelay"
    public static let hoverCloseDelay = prefix + "hoverCloseDelay"
    public static let reduceMotion = prefix + "reduceMotion"
    public static let launchAtLogin = prefix + "launchAtLogin"

    /// Reset Appearance removes these. `launchAtLogin` is not appearance.
    public static let appearanceAndBehavior: [String] = [
        theme,
        panelOpacity,
        panelSizeMode,
        panelWidth,
        panelHeight,
        backgroundMode,
        backgroundSolidColor,
        backgroundSolidOpacity,
        backgroundImageFilename,
        backgroundImageContentMode,
        backgroundImagePosition,
        backgroundImageOpacity,
        backgroundOverlayOpacity,
        edgeTabThickness,
        edgeTabLength,
        edgeTabColorMode,
        edgeTabCustomColor,
        edgeTabOpacity,
        hoverOpenDelay,
        hoverCloseDelay,
        reduceMotion,
    ]

    /// Phase 7 presets. Reset deletes them so a later migration cannot revive a short panel.
    public static let legacyLayoutKeys = [panelWidthPreset, panelHeightPreset]
}

public struct PreferencesStore {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> AppearancePreferences {
        migrateLayoutIfNeeded()
        let fallback = AppearancePreferences.default
        let loaded = AppearancePreferences(
            theme: enumValue(PreferencesKey.theme, fallback: fallback.theme),
            panelOpacity: double(PreferencesKey.panelOpacity, fallback: fallback.panelOpacity),
            panelSizeMode: enumValue(PreferencesKey.panelSizeMode, fallback: fallback.panelSizeMode),
            panelWidth: CGFloat(double(PreferencesKey.panelWidth, fallback: fallback.panelWidth)),
            panelHeight: CGFloat(double(PreferencesKey.panelHeight, fallback: fallback.panelHeight)),
            backgroundMode: enumValue(PreferencesKey.backgroundMode, fallback: fallback.backgroundMode),
            backgroundSolidColor: color(PreferencesKey.backgroundSolidColor, fallback: fallback.backgroundSolidColor),
            backgroundSolidOpacity: double(PreferencesKey.backgroundSolidOpacity, fallback: fallback.backgroundSolidOpacity),
            backgroundImageFilename: filename(PreferencesKey.backgroundImageFilename),
            backgroundImageContentMode: enumValue(
                PreferencesKey.backgroundImageContentMode,
                fallback: fallback.backgroundImageContentMode
            ),
            backgroundImagePosition: enumValue(
                PreferencesKey.backgroundImagePosition,
                fallback: fallback.backgroundImagePosition
            ),
            backgroundImageOpacity: double(PreferencesKey.backgroundImageOpacity, fallback: fallback.backgroundImageOpacity),
            backgroundOverlayOpacity: double(
                PreferencesKey.backgroundOverlayOpacity,
                fallback: fallback.backgroundOverlayOpacity
            ),
            edgeTabThickness: CGFloat(double(PreferencesKey.edgeTabThickness, fallback: fallback.edgeTabThickness)),
            edgeTabLength: CGFloat(double(PreferencesKey.edgeTabLength, fallback: fallback.edgeTabLength)),
            edgeTabColorMode: enumValue(PreferencesKey.edgeTabColorMode, fallback: fallback.edgeTabColorMode),
            edgeTabCustomColor: color(PreferencesKey.edgeTabCustomColor, fallback: fallback.edgeTabCustomColor),
            edgeTabOpacity: double(PreferencesKey.edgeTabOpacity, fallback: fallback.edgeTabOpacity),
            hoverOpenDelay: double(PreferencesKey.hoverOpenDelay, fallback: fallback.hoverOpenDelay),
            hoverCloseDelay: double(PreferencesKey.hoverCloseDelay, fallback: fallback.hoverCloseDelay),
            reduceMotion: bool(PreferencesKey.reduceMotion, fallback: fallback.reduceMotion),
            launchAtLogin: bool(PreferencesKey.launchAtLogin, fallback: fallback.launchAtLogin)
        )
        return loaded.clamped()
    }

    public func save(_ preferences: AppearancePreferences) {
        let value = preferences.clamped()
        defaults.set(value.theme.rawValue, forKey: PreferencesKey.theme)
        defaults.set(value.panelOpacity, forKey: PreferencesKey.panelOpacity)
        defaults.set(value.panelSizeMode.rawValue, forKey: PreferencesKey.panelSizeMode)
        defaults.set(Double(value.panelWidth), forKey: PreferencesKey.panelWidth)
        defaults.set(Double(value.panelHeight), forKey: PreferencesKey.panelHeight)
        defaults.set(PanelSizeMetrics.layoutMigrationVersion, forKey: PreferencesKey.layoutMigrationVersion)
        defaults.set(value.backgroundMode.rawValue, forKey: PreferencesKey.backgroundMode)
        defaults.set(value.backgroundSolidColor.hex, forKey: PreferencesKey.backgroundSolidColor)
        defaults.set(value.backgroundSolidOpacity, forKey: PreferencesKey.backgroundSolidOpacity)
        defaults.set(value.backgroundImageFilename ?? "", forKey: PreferencesKey.backgroundImageFilename)
        defaults.set(value.backgroundImageContentMode.rawValue, forKey: PreferencesKey.backgroundImageContentMode)
        defaults.set(value.backgroundImagePosition.rawValue, forKey: PreferencesKey.backgroundImagePosition)
        defaults.set(value.backgroundImageOpacity, forKey: PreferencesKey.backgroundImageOpacity)
        defaults.set(value.backgroundOverlayOpacity, forKey: PreferencesKey.backgroundOverlayOpacity)
        defaults.set(Double(value.edgeTabThickness), forKey: PreferencesKey.edgeTabThickness)
        defaults.set(Double(value.edgeTabLength), forKey: PreferencesKey.edgeTabLength)
        defaults.set(value.edgeTabColorMode.rawValue, forKey: PreferencesKey.edgeTabColorMode)
        defaults.set(value.edgeTabCustomColor.hex, forKey: PreferencesKey.edgeTabCustomColor)
        defaults.set(value.edgeTabOpacity, forKey: PreferencesKey.edgeTabOpacity)
        defaults.set(value.hoverOpenDelay, forKey: PreferencesKey.hoverOpenDelay)
        defaults.set(value.hoverCloseDelay, forKey: PreferencesKey.hoverCloseDelay)
        defaults.set(value.reduceMotion, forKey: PreferencesKey.reduceMotion)
        defaults.set(value.launchAtLogin, forKey: PreferencesKey.launchAtLogin)
    }

    /// Restores appearance and behavior. Does not write SQLite and keeps Launch at Login.
    public func resetAppearanceAndBehavior() {
        for key in PreferencesKey.appearanceAndBehavior + PreferencesKey.legacyLayoutKeys {
            defaults.removeObject(forKey: key)
        }
    }

    /// Runs once. Later launches, including a custom resize, are left alone.
    private func migrateLayoutIfNeeded() {
        guard defaults.integer(forKey: PreferencesKey.layoutMigrationVersion) < PanelSizeMetrics.layoutMigrationVersion else {
            return
        }
        let hasWidth = defaults.object(forKey: PreferencesKey.panelWidth) != nil
        let hasHeight = defaults.object(forKey: PreferencesKey.panelHeight) != nil
        if !hasWidth || !hasHeight {
            let mapped = PanelSizeMigration.map(
                widthPreset: optionalEnum(PreferencesKey.panelWidthPreset),
                heightPreset: optionalEnum(PreferencesKey.panelHeightPreset)
            )
            defaults.set(Double(mapped.width), forKey: PreferencesKey.panelWidth)
            defaults.set(Double(mapped.height), forKey: PreferencesKey.panelHeight)
            defaults.set(mapped.mode.rawValue, forKey: PreferencesKey.panelSizeMode)
        }
        defaults.set(PanelSizeMetrics.layoutMigrationVersion, forKey: PreferencesKey.layoutMigrationVersion)
    }

    private func optionalEnum<T: RawRepresentable>(_ key: String) -> T? where T.RawValue == String {
        guard let raw = defaults.string(forKey: key) else { return nil }
        return T(rawValue: raw)
    }

    private func double(_ key: String, fallback: Double) -> Double {
        guard defaults.object(forKey: key) != nil else { return fallback }
        return defaults.double(forKey: key)
    }

    private func bool(_ key: String, fallback: Bool) -> Bool {
        guard defaults.object(forKey: key) != nil else { return fallback }
        return defaults.bool(forKey: key)
    }

    private func enumValue<T: RawRepresentable>(_ key: String, fallback: T) -> T where T.RawValue == String {
        guard let raw = defaults.string(forKey: key), let value = T(rawValue: raw) else {
            return fallback
        }
        return value
    }

    /// Empty or unsafe values become nil. A full path is never accepted.
    private func filename(_ key: String) -> String? {
        guard let raw = defaults.string(forKey: key), BackgroundImageStore.isSafeFilename(raw) else {
            return nil
        }
        return raw
    }

    private func color(_ key: String, fallback: RGBAColor) -> RGBAColor {
        guard let raw = defaults.string(forKey: key), let parsed = RGBAColor.parse(hex: raw) else {
            return fallback
        }
        return parsed
    }
}
