import Foundation
import PeekMemoCore

enum PreferencesTestSupport {
    static func isolate() throws -> (defaults: UserDefaults, name: String) {
        let name = "PeekMemoPrefs-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: name) else {
            throw CheckError(message: "could not create UserDefaults suite")
        }
        defaults.removePersistentDomain(forName: name)
        return (defaults, name)
    }

    static func finish(_ defaults: UserDefaults, name: String) {
        defaults.removePersistentDomain(forName: name)
    }

    static func changed() -> AppearancePreferences {
        AppearancePreferences(
            theme: .dark,
            panelOpacity: 0.80,
            panelWidthPreset: .wide,
            panelHeightPreset: .small,
            edgeTabThickness: 6,
            edgeTabLength: 96,
            edgeTabColorMode: .custom,
            edgeTabCustomColor: RGBAColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 0.4),
            edgeTabOpacity: 0.33,
            hoverOpenDelay: 0.40,
            hoverCloseDelay: 0.75,
            reduceMotion: true,
            launchAtLogin: true
        )
    }
}
