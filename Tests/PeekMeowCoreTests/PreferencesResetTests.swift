import Foundation
import PeekMeowCore

enum PreferencesResetTests {
    static func run() throws {
        try resetRestoresAppearanceAndKeepsLogin()
        try resetDoesNotTouchSQLite()
    }

    static func resetRestoresAppearanceAndKeepsLogin() throws {
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        let store = PreferencesStore(defaults: isolated.defaults)
        store.save(PreferencesTestSupport.changed())
        store.resetAppearanceAndBehavior()
        for key in PreferencesKey.appearanceAndBehavior {
            try expect(isolated.defaults.object(forKey: key) == nil, "reset left \(key)")
        }
        try expect(isolated.defaults.object(forKey: PreferencesKey.launchAtLogin) != nil)
        let loaded = PreferencesStore(defaults: isolated.defaults).load()
        var expected = AppearancePreferences.default
        expected.launchAtLogin = true
        try expectEqual(loaded, expected)
    }

    static func resetDoesNotTouchSQLite() throws {
        let scratch = try PersistenceTestSupport.makeScratch()
        defer { PersistenceTestSupport.remove(scratch) }
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }

        let store = try PersistenceTestSupport.open(scratch)
        let work = try store.categories.fetchCategories().first { $0.name == "Work" }
        guard let work else { throw CheckError(message: "missing Work") }
        let color = RGBAColor(red: 0.2, green: 0.4, blue: 0.6)
        try store.categories.updateColor(id: work.id, color: color)
        try store.categories.renameCategory(id: work.id, name: "Work")
        let day = PersistenceTestSupport.today()
        let task = try store.memos.createTask(title: "Keep me", scheduledDate: day, categoryId: work.id)
        let note = try store.memos.createNote(title: "A note", scheduledDate: day, categoryId: nil)
        let categoryCount = try store.database.rowCount(in: "categories")
        let itemCount = try store.database.rowCount(in: "memo_items")

        let preferences = PreferencesStore(defaults: isolated.defaults)
        preferences.save(PreferencesTestSupport.changed())
        preferences.resetAppearanceAndBehavior()

        let reopened = try PersistenceTestSupport.open(scratch)
        try expectEqual(try reopened.database.rowCount(in: "categories"), categoryCount)
        try expectEqual(try reopened.database.rowCount(in: "memo_items"), itemCount)
        let categories = try reopened.categories.fetchCategories()
        let reloadedWork = categories.first { $0.id == work.id }
        guard let reloadedWork else { throw CheckError(message: "Work disappeared") }
        try expectEqual(reloadedWork.name, "Work")
        guard let parsed = RGBAColor.parse(hex: color.hex) else {
            throw CheckError(message: "category color hex did not parse")
        }
        try expectEqual(reloadedWork.color, parsed)
        try expectEqual(reloadedWork.isArchived, false)
        let items = try reopened.memos.fetchItems(for: day)
        let reloadedTask = items.first { $0.id == task.id }
        let reloadedNote = items.first { $0.id == note.id }
        guard let reloadedTask, let reloadedNote else {
            throw CheckError(message: "task or note disappeared")
        }
        try expectEqual(reloadedTask.title, "Keep me")
        try expectEqual(reloadedTask.isCompleted, false)
        try expectEqual(reloadedTask.scheduledDate, task.scheduledDate)
        try expectEqual(reloadedTask.categoryId, work.id)
        try expectEqual(reloadedNote.title, "A note")
        try expectEqual(reloadedNote.type, .note)
        try expectEqual(reloadedNote.categoryId, nil)
        let loaded = PreferencesStore(defaults: isolated.defaults).load()
        try expectEqual(loaded.panelOpacity, AppearancePreferences.default.panelOpacity)
        try expectEqual(loaded.launchAtLogin, true)
    }
}
