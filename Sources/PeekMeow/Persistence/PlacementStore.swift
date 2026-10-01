import Foundation
import PeekMeowCore

/// Temporary UserDefaults store. Replaced by SQLite in Phase 6.
enum PlacementStore {
    private static let key = "peekmeow.displayPlacements"

    static func load() -> [DisplayPlacement] {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return []
        }
        return (try? JSONDecoder().decode([DisplayPlacement].self, from: data)) ?? []
    }

    static func save(_ placements: [DisplayPlacement]) {
        guard let data = try? JSONEncoder().encode(placements) else {
            return
        }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func upsert(_ placement: DisplayPlacement) {
        var all = load()
        if let index = all.firstIndex(where: { $0.displayIdentifier == placement.displayIdentifier }) {
            all[index] = placement
        } else {
            all.append(placement)
        }
        save(all)
    }

    static func placement(for displayID: String) -> DisplayPlacement? {
        load().first(where: { $0.displayIdentifier == displayID })
    }
}
