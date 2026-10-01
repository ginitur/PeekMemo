using Microsoft.Data.Sqlite;
using PeekMemo.Core.Models;

namespace PeekMemo.Persistence;

public sealed class SqliteCategoryRepository : ICategoryRepository
{
    readonly MemoDatabase _database;

    public SqliteCategoryRepository(MemoDatabase database)
    {
        _database = database;
    }

    public IReadOnlyList<Category> ListAll() =>
        _database.Read(connection => Read(connection, null, includeArchived: true));

    public IReadOnlyList<Category> ListActive() =>
        _database.Read(connection => Read(connection, null, includeArchived: false));

    public Category Create(string name, string? icon = null, string? color = null)
    {
        var text = RequireName(name);
        var now = _database.Clock();
        Category? created = null;
        _database.Write((connection, transaction) =>
        {
            var order = NextOrder(connection, transaction);
            created = new Category(Guid.NewGuid(), text, icon, color, order, false, now, now);
            Insert(connection, transaction, created);
        });
        return created ?? throw new PersistenceException("Category insert did not complete.");
    }

    public void Insert(Category category)
    {
        _database.Write((connection, transaction) => Insert(connection, transaction, category));
    }

    public void Rename(Guid id, string name)
    {
        var text = RequireName(name);
        var now = _database.Dates.StoreInstant(_database.Clock());
        _database.Write((connection, transaction) =>
        {
            var changed = Execute(
                connection,
                transaction,
                "UPDATE categories SET name = @name, updated_at = @at WHERE id = @id",
                ("@name", text),
                ("@at", now),
                ("@id", EntityId.Format(id)));
            if (changed == 0)
            {
                throw new PersistenceException($"Category {EntityId.Format(id)} was not found.");
            }
        });
    }

    public void Archive(Guid id)
    {
        var now = _database.Dates.StoreInstant(_database.Clock());
        _database.Write((connection, transaction) =>
        {
            var changed = Execute(
                connection,
                transaction,
                "UPDATE categories SET is_archived = 1, updated_at = @at WHERE id = @id",
                ("@at", now),
                ("@id", EntityId.Format(id)));
            if (changed == 0)
            {
                throw new PersistenceException($"Category {EntityId.Format(id)} was not found.");
            }
        });
    }

    public void UpdateColor(Guid id, string? color)
    {
        var now = _database.Dates.StoreInstant(_database.Clock());
        _database.Write((connection, transaction) =>
        {
            var changed = Execute(
                connection,
                transaction,
                "UPDATE categories SET color = @color, updated_at = @at WHERE id = @id",
                ("@color", (object?)color ?? DBNull.Value),
                ("@at", now),
                ("@id", EntityId.Format(id)));
            if (changed == 0)
            {
                throw new PersistenceException($"Category {EntityId.Format(id)} was not found.");
            }
        });
    }

    public void Update(Category category)
    {
        _database.Write((connection, transaction) =>
        {
            var changed = Execute(
                connection,
                transaction,
                """
                UPDATE categories
                SET name = @name, icon = @icon, color = @color, sort_order = @sort,
                    is_archived = @archived, updated_at = @at
                WHERE id = @id
                """,
                ("@name", category.Name),
                ("@icon", (object?)category.Icon ?? DBNull.Value),
                ("@color", (object?)category.Color ?? DBNull.Value),
                ("@sort", category.SortOrder),
                ("@archived", category.IsArchived ? 1 : 0),
                ("@at", _database.Dates.StoreInstant(category.UpdatedAt)),
                ("@id", EntityId.Format(category.Id)));
            if (changed == 0)
            {
                throw new PersistenceException($"Category {EntityId.Format(category.Id)} was not found.");
            }
        });
    }

    public void Reorder(IReadOnlyList<Guid> orderedIds)
    {
        var now = _database.Dates.StoreInstant(_database.Clock());
        _database.Write((connection, transaction) =>
        {
            for (var index = 0; index < orderedIds.Count; index++)
            {
                Execute(
                    connection,
                    transaction,
                    "UPDATE categories SET sort_order = @sort, updated_at = @at WHERE id = @id",
                    ("@sort", index),
                    ("@at", now),
                    ("@id", EntityId.Format(orderedIds[index])));
            }
        });
    }

    public void Delete(Guid id)
    {
        _database.Write((connection, transaction) =>
        {
            var changed = Execute(
                connection,
                transaction,
                "DELETE FROM categories WHERE id = @id",
                ("@id", EntityId.Format(id)));
            if (changed == 0)
            {
                throw new PersistenceException($"Category {EntityId.Format(id)} was not found.");
            }
        });
    }

    List<Category> Read(SqliteConnection connection, SqliteTransaction? transaction, bool includeArchived)
    {
        using var command = SqliteCommand(connection, transaction, includeArchived
            ? "SELECT id, name, icon, color, sort_order, is_archived, created_at, updated_at FROM categories ORDER BY sort_order"
            : "SELECT id, name, icon, color, sort_order, is_archived, created_at, updated_at FROM categories WHERE is_archived = 0 ORDER BY sort_order");
        using var reader = command.ExecuteReader();
        var rows = new List<Category>();
        while (reader.Read())
        {
            rows.Add(new Category(
                EntityId.Parse(reader.GetString(0)),
                reader.GetString(1),
                reader.IsDBNull(2) ? null : reader.GetString(2),
                reader.IsDBNull(3) ? null : reader.GetString(3),
                reader.GetInt32(4),
                reader.GetInt32(5) != 0,
                _database.Dates.ReadInstant(reader.GetString(6)),
                _database.Dates.ReadInstant(reader.GetString(7))));
        }

        return rows;
    }

    void Insert(SqliteConnection connection, SqliteTransaction transaction, Category category)
    {
        Execute(
            connection,
            transaction,
            """
            INSERT INTO categories (id, name, icon, color, sort_order, is_archived, created_at, updated_at)
            VALUES (@id, @name, @icon, @color, @sort, @archived, @created, @updated)
            """,
            ("@id", EntityId.Format(category.Id)),
            ("@name", category.Name),
            ("@icon", (object?)category.Icon ?? DBNull.Value),
            ("@color", (object?)category.Color ?? DBNull.Value),
            ("@sort", category.SortOrder),
            ("@archived", category.IsArchived ? 1 : 0),
            ("@created", _database.Dates.StoreInstant(category.CreatedAt)),
            ("@updated", _database.Dates.StoreInstant(category.UpdatedAt)));
    }

    int NextOrder(SqliteConnection connection, SqliteTransaction transaction)
    {
        using var command = SqliteCommand(
            connection,
            transaction,
            "SELECT COALESCE(MAX(sort_order), -1) + 1 FROM categories");
        return Convert.ToInt32(command.ExecuteScalar(), System.Globalization.CultureInfo.InvariantCulture);
    }

    static string RequireName(string name)
    {
        var text = name.Trim();
        if (text.Length == 0)
        {
            throw new PersistenceException("A category name is required.");
        }

        return text;
    }

    static SqliteCommand SqliteCommand(SqliteConnection connection, SqliteTransaction? transaction, string sql)
    {
        var command = connection.CreateCommand();
        command.Transaction = transaction;
        command.CommandText = sql;
        return command;
    }

    static int Execute(
        SqliteConnection connection,
        SqliteTransaction transaction,
        string sql,
        params (string Name, object Value)[] parameters)
    {
        using var command = SqliteCommand(connection, transaction, sql);
        foreach (var (name, value) in parameters)
        {
            command.Parameters.AddWithValue(name, value);
        }

        return command.ExecuteNonQuery();
    }
}
