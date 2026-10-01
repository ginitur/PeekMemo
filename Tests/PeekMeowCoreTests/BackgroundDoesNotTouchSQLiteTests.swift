import Foundation
import PeekMeowCore

enum BackgroundDoesNotTouchSQLiteTests {
    static func run() throws {
        try backgroundFilesAndPreferencesLeaveTheDatabaseAlone()
    }

    static func backgroundFilesAndPreferencesLeaveTheDatabaseAlone() throws {
        let database = try PersistenceTestSupport.makeScratch()
        defer { PersistenceTestSupport.remove(database) }
        let backgrounds = FileManager.default.temporaryDirectory
            .appendingPathComponent("PeekMeowBgSQL-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: backgrounds) }
        try expect(!backgrounds.path.contains("Application Support"))

        let taskID: UUID
        let noteID: UUID
        let workID: UUID
        let scheduled: Date
        do {
            let store = try PersistenceTestSupport.open(database)
            try expectEqual(try store.database.appliedMigrationIdentifiers(), ["v1_initial_schema"])
            let work = try store.categories.fetchCategories().first { $0.name == "Work" }
            guard let work else { throw CheckError(message: "missing Work") }
            workID = work.id
            scheduled = PersistenceTestSupport.today()
            let task = try store.memos.createTask(title: "Keep me", scheduledDate: scheduled, categoryId: work.id)
            let note = try store.memos.createNote(title: "A note", scheduledDate: scheduled, categoryId: nil)
            taskID = task.id
            noteID = note.id
            try expectEqual(
                try store.database.columnNames(in: "memo_items"),
                [
                    "id", "category_id", "parent_id", "type", "title", "body",
                    "is_completed", "completed_at", "sort_order", "scheduled_date",
                    "due_date", "is_archived", "created_at", "updated_at",
                ]
            )
        }

        let before = try Data(contentsOf: URL(fileURLWithPath: database.path))
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        let source = backgrounds.appendingPathComponent("original.png")
        try FileManager.default.createDirectory(at: backgrounds, withIntermediateDirectories: true)
        try BackgroundImageFixtures.png.write(to: source)
        let images = BackgroundImageStore(directory: backgrounds.appendingPathComponent("Backgrounds", isDirectory: true))
        let filename = try images.install(from: source)
        let preferences = PreferencesStore(defaults: isolated.defaults)
        preferences.save(AppearancePreferences(
            backgroundMode: .image,
            backgroundImageFilename: filename,
            backgroundImageContentMode: .fill,
            backgroundImageOpacity: 0.60,
            backgroundOverlayOpacity: 0.25
        ))
        let loaded = preferences.load()
        try expectEqual(loaded.backgroundImageFilename, filename)
        try expect(images.removeManaged(filename: filename))
        try expectEqual(try Data(contentsOf: source), BackgroundImageFixtures.png)
        preferences.save(AppearancePreferences(backgroundMode: .systemMaterial, backgroundImageFilename: nil))

        let after = try Data(contentsOf: URL(fileURLWithPath: database.path))
        try expectEqual(after, before)

        let reopened = try PersistenceTestSupport.open(database)
        try expectEqual(try reopened.database.appliedMigrationIdentifiers(), ["v1_initial_schema"])
        try expectEqual(try reopened.database.rowCount(in: "categories"), 2)
        try expectEqual(try reopened.database.rowCount(in: "memo_items"), 2)
        let items = try reopened.memos.fetchItems(for: scheduled)
        let task = items.first { $0.id == taskID }
        let note = items.first { $0.id == noteID }
        guard let task, let note else { throw CheckError(message: "task or note disappeared") }
        try expectEqual(task.title, "Keep me")
        try expectEqual(task.categoryId, workID)
        try expectEqual(task.isCompleted, false)
        try expectEqual(note.title, "A note")
        try expectEqual(note.type, .note)
        try expect(!database.path.contains("Backgrounds"))
        try expect(images.existingFile(filename: filename) == nil)
    }
}
