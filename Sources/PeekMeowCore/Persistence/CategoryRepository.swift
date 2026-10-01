import Foundation
import GRDB

public struct CategoryRepository: Sendable {
    let writer: DatabaseQueue

    public init(writer: DatabaseQueue) {
        self.writer = writer
    }

    public func fetchCategories(includingArchived: Bool = false) throws -> [Category] {
        try writer.read { db in
            var request = CategoryRecord.order(Column("sort_order"))
            if !includingArchived {
                request = request.filter(Column("is_archived") == false)
            }
            return try request.fetchAll(db).map { try $0.model() }
        }
    }

    @discardableResult
    public func createCategory(name: String, icon: String = "folder", color: RGBAColor = .accent) throws -> Category {
        try writer.write { db in
            let order = try Int.fetchOne(
                db,
                sql: "SELECT COALESCE(MAX(sort_order), -1) + 1 FROM categories"
            ) ?? 0
            let now = Date()
            let category = Category(
                name: name,
                icon: icon,
                color: color,
                sortOrder: order,
                createdAt: now,
                updatedAt: now
            )
            try CategoryRecord(category).insert(db)
            return category
        }
    }

    public func renameCategory(id: UUID, name: String) throws {
        try writer.write { db in
            try db.execute(
                sql: "UPDATE categories SET name = ?, updated_at = ? WHERE id = ?",
                arguments: [name, Date(), id.uuidString]
            )
            if db.changesCount == 0 {
                throw PersistenceError.notFound(id)
            }
        }
    }

    public func updateColor(id: UUID, color: RGBAColor) throws {
        try writer.write { db in
            try db.execute(
                sql: "UPDATE categories SET color = ?, updated_at = ? WHERE id = ?",
                arguments: [color.hex, Date(), id.uuidString]
            )
            if db.changesCount == 0 {
                throw PersistenceError.notFound(id)
            }
        }
    }

    public func archiveCategory(id: UUID) throws {
        try writer.write { db in
            try db.execute(
                sql: "UPDATE categories SET is_archived = 1, updated_at = ? WHERE id = ?",
                arguments: [Date(), id.uuidString]
            )
            if db.changesCount == 0 {
                throw PersistenceError.notFound(id)
            }
        }
    }

    public func reorderCategories(_ ids: [UUID]) throws {
        try writer.write { db in
            let now = Date()
            for (index, id) in ids.enumerated() {
                try db.execute(
                    sql: "UPDATE categories SET sort_order = ?, updated_at = ? WHERE id = ?",
                    arguments: [index, now, id.uuidString]
                )
            }
        }
    }
}
