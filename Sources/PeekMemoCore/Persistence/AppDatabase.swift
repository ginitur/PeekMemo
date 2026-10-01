import Foundation
import GRDB

/// Opens SQLite and runs migrations. Never deletes a database that fails to open or migrate.
public final class AppDatabase: Sendable {
    public let path: String
    let writer: DatabaseQueue

    public init(path: String) throws {
        self.path = path
        var configuration = Configuration()
        configuration.foreignKeysEnabled = true
        configuration.label = "PeekMemo"
        let queue = try DatabaseQueue(path: path, configuration: configuration)
        try PersistenceMigrator.migrator.migrate(queue)
        writer = queue
    }

    public static func openDefault() throws -> AppDatabase {
        let url = try DatabaseLocation.defaultDatabaseURL()
        return try AppDatabase(path: url.path)
    }

    public func appliedMigrationIdentifiers() throws -> [String] {
        try writer.read { db in
            try String.fetchAll(db, sql: "SELECT identifier FROM grdb_migrations ORDER BY identifier")
        }
    }

    public func foreignKeysEnabled() throws -> Bool {
        try writer.read { db in
            try Int.fetchOne(db, sql: "PRAGMA foreign_keys") == 1
        }
    }

    package func columnNames(in table: String) throws -> [String] {
        try Self.requireKnownTable(table)
        return try writer.read { db in
            try String.fetchAll(db, sql: "SELECT name FROM pragma_table_info('\(table)') ORDER BY cid")
        }
    }

    package func indexNames(on table: String) throws -> [String] {
        try Self.requireKnownTable(table)
        return try writer.read { db in
            try String.fetchAll(
                db,
                sql: """
                SELECT name FROM sqlite_master
                WHERE type = 'index' AND tbl_name = ? AND name NOT LIKE 'sqlite_%'
                ORDER BY name
                """,
                arguments: [table]
            )
        }
    }

    package func rowCount(in table: String) throws -> Int {
        try Self.requireKnownTable(table)
        return try writer.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \(table)") ?? 0
        }
    }

    package func deleteAllRows(in table: String) throws {
        try Self.requireKnownTable(table)
        try writer.write { db in
            try db.execute(sql: "DELETE FROM \(table)")
        }
    }

    /// Test hook for constraint failures. Not used by the UI.
    package func executeSQL(_ sql: String) throws {
        try writer.write { db in
            try db.execute(sql: sql)
        }
    }

    private static func requireKnownTable(_ table: String) throws {
        guard table == "categories" || table == "memo_items" else {
            throw PersistenceError.databaseUnavailable("unknown table \(table)")
        }
    }
}
