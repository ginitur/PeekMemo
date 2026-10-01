import Foundation
import GRDB

enum PersistenceMigrator {
    static let initial = "v1_initial_schema"

    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        // A schema mismatch must fail in place. Never delete and recreate the user's database.
        migrator.eraseDatabaseOnSchemaChange = false
        migrator.registerMigration(initial) { db in
            try db.create(table: "categories") { table in
                table.primaryKey("id", .text)
                table.column("name", .text).notNull()
                table.column("icon", .text)
                table.column("color", .text)
                table.column("sort_order", .integer).notNull()
                table.column("is_archived", .integer).notNull().defaults(to: 0)
                table.column("created_at", .datetime).notNull()
                table.column("updated_at", .datetime).notNull()
            }

            try db.create(table: "memo_items") { table in
                table.primaryKey("id", .text)
                table.column("category_id", .text)
                    .references("categories", onDelete: .setNull)
                table.column("parent_id", .text)
                    .references("memo_items", onDelete: .cascade)
                table.column("type", .text).notNull()
                table.column("title", .text).notNull()
                table.column("body", .text)
                table.column("is_completed", .integer).notNull().defaults(to: 0)
                table.column("completed_at", .datetime)
                table.column("sort_order", .integer).notNull()
                table.column("scheduled_date", .datetime)
                table.column("due_date", .datetime)
                table.column("is_archived", .integer).notNull().defaults(to: 0)
                table.column("created_at", .datetime).notNull()
                table.column("updated_at", .datetime).notNull()
            }

            try db.create(index: "memo_items_on_scheduled_date", on: "memo_items", columns: ["scheduled_date"])
            try db.create(index: "memo_items_on_category_id", on: "memo_items", columns: ["category_id"])
            try db.create(index: "memo_items_on_parent_id", on: "memo_items", columns: ["parent_id"])
            try db.create(index: "memo_items_on_is_completed", on: "memo_items", columns: ["is_completed"])
            try db.create(
                index: "memo_items_on_scheduled_date_category_id",
                on: "memo_items",
                columns: ["scheduled_date", "category_id"]
            )

            let now = Date()
            let work = Category(
                name: "Work",
                icon: "briefcase",
                color: .today,
                sortOrder: 0,
                createdAt: now,
                updatedAt: now
            )
            let personal = Category(
                name: "Personal",
                icon: "house",
                color: RGBAColor(red: 0.2, green: 0.7, blue: 0.45),
                sortOrder: 1,
                createdAt: now,
                updatedAt: now
            )
            try CategoryRecord(work).insert(db)
            try CategoryRecord(personal).insert(db)
        }
        return migrator
    }
}
