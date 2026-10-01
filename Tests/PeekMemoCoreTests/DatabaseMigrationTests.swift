import Foundation
import PeekMemoCore

enum DatabaseMigrationTests {
    static func run() throws {
        try freshDatabaseHasV1SchemaAndSeed()
        try reopeningDoesNotReseedDeletedCategories()
        try archivingCategoriesIsNotUndoneOnLaunch()
        try failedOpenDoesNotDeleteTheFile()
        try foreignKeyRejectsUnknownCategory()
    }

    static func freshDatabaseHasV1SchemaAndSeed() throws {
        let scratch = try PersistenceTestSupport.makeScratch()
        defer { PersistenceTestSupport.remove(scratch) }
        let store = try PersistenceTestSupport.open(scratch)

        try expectEqual(try store.database.appliedMigrationIdentifiers(), ["v1_initial_schema"])
        let foreignKeys = try store.database.foreignKeysEnabled()
        try expect(foreignKeys)

        let categoryColumns = try store.database.columnNames(in: "categories")
        try expectEqual(
            categoryColumns,
            ["id", "name", "icon", "color", "sort_order", "is_archived", "created_at", "updated_at"]
        )
        let itemColumns = try store.database.columnNames(in: "memo_items")
        try expectEqual(
            itemColumns,
            [
                "id", "category_id", "parent_id", "type", "title", "body",
                "is_completed", "completed_at", "sort_order", "scheduled_date",
                "due_date", "is_archived", "created_at", "updated_at",
            ]
        )
        try expect(!itemColumns.contains("for_today"))
        try expect(!itemColumns.contains("forToday"))

        try expectEqual(
            try store.database.indexNames(on: "memo_items"),
            [
                "memo_items_on_category_id",
                "memo_items_on_is_completed",
                "memo_items_on_parent_id",
                "memo_items_on_scheduled_date",
                "memo_items_on_scheduled_date_category_id",
            ]
        )

        let categories = try store.categories.fetchCategories()
        try expectEqual(categories.map(\.name), ["Work", "Personal"])
        try expectEqual(try store.database.rowCount(in: "memo_items"), 0)
        let forbidden = ["Inbox", "Ideas", "Completed", "Today"]
        try expect(categories.allSatisfy { !forbidden.contains($0.name) })
    }

    static func reopeningDoesNotReseedDeletedCategories() throws {
        let scratch = try PersistenceTestSupport.makeScratch()
        defer { PersistenceTestSupport.remove(scratch) }
        let first = try PersistenceTestSupport.open(scratch)
        try expectEqual(try first.database.rowCount(in: "categories"), 2)
        try first.database.deleteAllRows(in: "categories")
        try expectEqual(try first.database.rowCount(in: "categories"), 0)

        let reopened = try PersistenceTestSupport.open(scratch)
        try expectEqual(try reopened.database.rowCount(in: "categories"), 0)
        try expectEqual(try reopened.database.appliedMigrationIdentifiers(), ["v1_initial_schema"])
    }

    static func archivingCategoriesIsNotUndoneOnLaunch() throws {
        let scratch = try PersistenceTestSupport.makeScratch()
        defer { PersistenceTestSupport.remove(scratch) }
        let first = try PersistenceTestSupport.open(scratch)
        let original = try first.categories.fetchCategories()
        for category in original {
            try first.categories.archiveCategory(id: category.id)
        }

        let reopened = try PersistenceTestSupport.open(scratch)
        let visible = try reopened.categories.fetchCategories()
        try expect(visible.isEmpty)
        let stored = try reopened.categories.fetchCategories(includingArchived: true)
        try expectEqual(stored.map(\.id), original.map(\.id))
        try expect(stored.allSatisfy(\.isArchived))
        try expectEqual(stored.count, 2)
    }

    static func failedOpenDoesNotDeleteTheFile() throws {
        let scratch = try PersistenceTestSupport.makeScratch()
        defer { PersistenceTestSupport.remove(scratch) }
        let url = URL(fileURLWithPath: scratch.path)
        let payload = Data("this is not a sqlite database".utf8)
        try payload.write(to: url)

        do {
            _ = try AppDatabase(path: scratch.path)
            try expect(false, "opening a corrupt file should fail")
        } catch {
            // Expected. The original file must still be there, unmodified.
        }

        try expect(FileManager.default.fileExists(atPath: scratch.path))
        try expectEqual(try Data(contentsOf: url), payload)
    }

    static func foreignKeyRejectsUnknownCategory() throws {
        let scratch = try PersistenceTestSupport.makeScratch()
        defer { PersistenceTestSupport.remove(scratch) }
        let store = try PersistenceTestSupport.open(scratch)
        let id = UUID().uuidString
        let missing = UUID().uuidString
        let now = Date().timeIntervalSince1970
        let sql = """
        INSERT INTO memo_items (
            id, category_id, type, title, is_completed, sort_order, is_archived, created_at, updated_at
        ) VALUES ('\(id)', '\(missing)', 'task', 'orphan', 0, 0, 0, \(now), \(now))
        """
        do {
            try store.database.executeSQL(sql)
            try expect(false, "foreign key should reject an unknown category")
        } catch is CheckError {
            throw CheckError(message: "foreign key was not enforced")
        } catch {
            // Constraint failure. The database file is still the one we opened.
        }
        try expect(FileManager.default.fileExists(atPath: scratch.path))
        try expectEqual(try store.database.rowCount(in: "memo_items"), 0)
    }
}
