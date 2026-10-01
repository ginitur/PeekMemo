using Microsoft.Data.Sqlite;

namespace PeekMemo.Persistence;

/// Versioned schema. A failure rolls the transaction back and leaves the file in place.
public static class SchemaMigrator
{
    public const string InitialId = "v1_initial_schema";
    public const int InitialUserVersion = 1;

    public static void Apply(SqliteConnection connection, DateStorageMapper dates, Func<DateTimeOffset> clock)
    {
        if (IsApplied(connection))
        {
            return;
        }

        using var transaction = connection.BeginTransaction();
        try
        {
            Execute(connection, transaction, """
                CREATE TABLE schema_migrations (
                    id TEXT PRIMARY KEY NOT NULL,
                    applied_at TEXT NOT NULL
                )
                """);
            Execute(connection, transaction, """
                CREATE TABLE categories (
                    id TEXT PRIMARY KEY NOT NULL,
                    name TEXT NOT NULL,
                    icon TEXT NULL,
                    color TEXT NULL,
                    sort_order INTEGER NOT NULL,
                    is_archived INTEGER NOT NULL DEFAULT 0,
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL
                )
                """);
            Execute(connection, transaction, """
                CREATE TABLE memo_items (
                    id TEXT PRIMARY KEY NOT NULL,
                    category_id TEXT NULL REFERENCES categories(id) ON DELETE SET NULL,
                    parent_id TEXT NULL REFERENCES memo_items(id) ON DELETE CASCADE,
                    type TEXT NOT NULL,
                    title TEXT NOT NULL,
                    body TEXT NULL,
                    is_completed INTEGER NOT NULL DEFAULT 0,
                    completed_at TEXT NULL,
                    sort_order INTEGER NOT NULL,
                    scheduled_date TEXT NULL,
                    due_date TEXT NULL,
                    is_archived INTEGER NOT NULL DEFAULT 0,
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL
                )
                """);
            Execute(connection, transaction, "CREATE INDEX memo_items_on_scheduled_date ON memo_items(scheduled_date)");
            Execute(connection, transaction, "CREATE INDEX memo_items_on_category_id ON memo_items(category_id)");
            Execute(connection, transaction, "CREATE INDEX memo_items_on_parent_id ON memo_items(parent_id)");
            Execute(connection, transaction, "CREATE INDEX memo_items_on_is_completed ON memo_items(is_completed)");
            Execute(connection, transaction, "CREATE INDEX memo_items_on_scheduled_date_category_id ON memo_items(scheduled_date, category_id)");
            SeedCategories(connection, transaction, dates, clock());
            Execute(connection, transaction, "INSERT INTO schema_migrations (id, applied_at) VALUES (@id, @at)",
                ("@id", InitialId),
                ("@at", dates.StoreInstant(clock())));
            Execute(connection, transaction, $"PRAGMA user_version = {InitialUserVersion}");
            transaction.Commit();
        }
        catch (Exception exception)
        {
            TryRollback(transaction);
            throw new PersistenceException(
                "Schema migration failed. The database file was not deleted.",
                exception);
        }
    }

    public static bool IsApplied(SqliteConnection connection)
    {
        if (!TableExists(connection, "schema_migrations"))
        {
            return false;
        }

        using var command = connection.CreateCommand();
        command.CommandText = "SELECT COUNT(*) FROM schema_migrations WHERE id = @id";
        command.Parameters.AddWithValue("@id", InitialId);
        return Convert.ToInt32(command.ExecuteScalar(), System.Globalization.CultureInfo.InvariantCulture) > 0;
    }

    public static int UserVersion(SqliteConnection connection)
    {
        using var command = connection.CreateCommand();
        command.CommandText = "PRAGMA user_version";
        return Convert.ToInt32(command.ExecuteScalar(), System.Globalization.CultureInfo.InvariantCulture);
    }

    static void SeedCategories(
        SqliteConnection connection,
        SqliteTransaction transaction,
        DateStorageMapper dates,
        DateTimeOffset now)
    {
        var stamp = dates.StoreInstant(now);
        InsertCategory(connection, transaction, "Work", "briefcase", Hex(0.20, 0.48, 0.96), 0, stamp);
        InsertCategory(connection, transaction, "Personal", "house", Hex(0.20, 0.70, 0.45), 1, stamp);
    }

    static void InsertCategory(
        SqliteConnection connection,
        SqliteTransaction transaction,
        string name,
        string icon,
        string color,
        int sortOrder,
        string stamp)
    {
        Execute(
            connection,
            transaction,
            """
            INSERT INTO categories (id, name, icon, color, sort_order, is_archived, created_at, updated_at)
            VALUES (@id, @name, @icon, @color, @sort, 0, @stamp, @stamp)
            """,
            ("@id", Guid.NewGuid().ToString("D").ToUpperInvariant()),
            ("@name", name),
            ("@icon", icon),
            ("@color", color),
            ("@sort", sortOrder),
            ("@stamp", stamp));
    }

    /// Matches Swift `rounded()` (to-nearest, ties to even) used by the macOS color hex.
    public static string Hex(double red, double green, double blue)
    {
        var r = (int)Math.Round(red * 255, MidpointRounding.ToEven);
        var g = (int)Math.Round(green * 255, MidpointRounding.ToEven);
        var b = (int)Math.Round(blue * 255, MidpointRounding.ToEven);
        return $"#{r:X2}{g:X2}{b:X2}";
    }

    static bool TableExists(SqliteConnection connection, string name)
    {
        using var command = connection.CreateCommand();
        command.CommandText = "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = @name";
        command.Parameters.AddWithValue("@name", name);
        var result = command.ExecuteScalar();
        return result is not null && result is not DBNull;
    }

    static void Execute(
        SqliteConnection connection,
        SqliteTransaction transaction,
        string sql,
        params (string Name, object Value)[] parameters)
    {
        using var command = connection.CreateCommand();
        command.Transaction = transaction;
        command.CommandText = sql;
        foreach (var (name, value) in parameters)
        {
            command.Parameters.AddWithValue(name, value);
        }

        command.ExecuteNonQuery();
    }

    static void TryRollback(SqliteTransaction transaction)
    {
        try
        {
            transaction.Rollback();
        }
        catch (InvalidOperationException)
        {
        }
    }
}
