using Microsoft.Data.Sqlite;
using PeekMemo.Core.Daily;
using PeekMemo.Core.Models;

namespace PeekMemo.Persistence;

public sealed class SqliteMemoRepository : IMemoRepository
{
    readonly MemoDatabase _database;

    public SqliteMemoRepository(MemoDatabase database)
    {
        _database = database;
    }

    public IReadOnlyList<MemoItem> ListAll() =>
        _database.Read(connection => Read(connection, null, "SELECT " + Columns + " FROM memo_items ORDER BY sort_order"));

    public IReadOnlyList<MemoItem> QueryDaily(DateOnly day, Guid? categoryId)
    {
        var (start, next) = _database.Dates.DayRange(day);
        return _database.Read(connection => Read(
            connection,
            null,
            MemoSql.DailyItems,
            ("@start", start),
            ("@next", next),
            ("@category", CategoryParameter(categoryId))));
    }

    public IReadOnlyList<MemoItem> QueryPastUnfinished(DateOnly today, Guid? categoryId)
    {
        var start = _database.Dates.StoreDay(today);
        return _database.Read(connection => Read(
            connection,
            null,
            MemoSql.PastUnfinished,
            ("@start", start),
            ("@category", CategoryParameter(categoryId))));
    }

    public MemoItem CreateTask(string title, DateOnly scheduled, Guid? categoryId, int? sortOrder = null)
    {
        var text = RequireTitle(title);
        MemoItem? created = null;
        _database.Write((connection, transaction) =>
        {
            var order = sortOrder ?? NextRootOrder(connection, transaction, scheduled);
            var now = _database.Clock();
            created = MemoItem.Create(MemoItemType.Task, text, scheduled, categoryId, sortOrder: order, timestamp: now);
            Insert(connection, transaction, created);
        });
        return created ?? throw new PersistenceException("Task insert did not complete.");
    }

    public MemoItem CreateNote(string title, DateOnly scheduled, Guid? categoryId, string? body = null)
    {
        var text = RequireTitle(title);
        MemoItem? created = null;
        _database.Write((connection, transaction) =>
        {
            var order = NextRootOrder(connection, transaction, scheduled);
            var now = _database.Clock();
            created = MemoItem.Create(
                MemoItemType.Note,
                text,
                scheduled,
                categoryId,
                sortOrder: order,
                body: body,
                timestamp: now);
            Insert(connection, transaction, created);
        });
        return created ?? throw new PersistenceException("Note insert did not complete.");
    }

    public MemoItem CreateSubtask(Guid parentId, string title)
    {
        var text = RequireTitle(title);
        MemoItem? created = null;
        _database.Write((connection, transaction) =>
        {
            var parent = Find(connection, transaction, parentId)
                ?? throw new PersistenceException($"Memo {EntityId.Format(parentId)} was not found.");
            if (parent.Type != MemoItemType.Task)
            {
                throw new PersistenceException("A note cannot have a subtask.");
            }

            if (parent.ParentId is not null)
            {
                throw new PersistenceException("A subtask cannot have its own subtask.");
            }

            var order = NextChildOrder(connection, transaction, parentId);
            var now = _database.Clock();
            created = MemoItem.Create(
                MemoItemType.Task,
                text,
                parent.ScheduledDate,
                parent.CategoryId,
                parent.Id,
                order,
                timestamp: now);
            Insert(connection, transaction, created);
        });
        return created ?? throw new PersistenceException("Subtask insert did not complete.");
    }

    public void Insert(MemoItem item) =>
        _database.Write((connection, transaction) => Insert(connection, transaction, item));

    public void Update(MemoItem item) =>
        _database.Write((connection, transaction) => Update(connection, transaction, item));

    public void Delete(Guid id)
    {
        _database.Write((connection, transaction) =>
        {
            var changed = Execute(
                connection,
                transaction,
                "DELETE FROM memo_items WHERE id = @id",
                ("@id", EntityId.Format(id)));
            if (changed == 0)
            {
                throw new PersistenceException($"Memo {EntityId.Format(id)} was not found.");
            }
        });
    }

    public void SetCompleted(Guid id, bool completed, DateTimeOffset at)
    {
        _database.Write((connection, transaction) =>
        {
            var all = Read(connection, transaction, "SELECT " + Columns + " FROM memo_items");
            var current = all.FirstOrDefault(item => item.Id == id);
            if (current is null)
            {
                throw new PersistenceException($"Memo {EntityId.Format(id)} was not found.");
            }

            if (current.Type == MemoItemType.Note)
            {
                return;
            }

            var next = CompletionRules.SetCompleted(all, id, completed, at);
            foreach (var item in next)
            {
                var previous = all.First(candidate => candidate.Id == item.Id);
                if (previous.IsCompleted != item.IsCompleted || previous.CompletedAt != item.CompletedAt)
                {
                    Update(connection, transaction, item);
                }
            }
        });
    }

    const string Columns =
        "id, category_id, parent_id, type, title, body, is_completed, completed_at, sort_order, scheduled_date, due_date, is_archived, created_at, updated_at";

    List<MemoItem> Read(
        SqliteConnection connection,
        SqliteTransaction? transaction,
        string sql,
        params (string Name, object Value)[] parameters)
    {
        using var command = SqliteCommand(connection, transaction, sql);
        foreach (var (name, value) in parameters)
        {
            command.Parameters.AddWithValue(name, value);
        }

        using var reader = command.ExecuteReader();
        var rows = new List<MemoItem>();
        while (reader.Read())
        {
            rows.Add(ReadItem(reader));
        }

        return rows;
    }

    MemoItem ReadItem(SqliteDataReader reader)
    {
        var scheduled = reader.IsDBNull(9)
            ? throw new PersistenceException($"Memo {reader.GetString(0)} has no scheduled day.")
            : _database.Dates.ReadDay(reader.GetString(9));
        return new MemoItem(
            EntityId.Parse(reader.GetString(0)),
            reader.IsDBNull(1) ? null : EntityId.Parse(reader.GetString(1)),
            reader.IsDBNull(2) ? null : EntityId.Parse(reader.GetString(2)),
            ParseType(reader.GetString(3)),
            reader.GetString(4),
            reader.IsDBNull(5) ? null : reader.GetString(5),
            reader.GetInt32(6) != 0,
            reader.IsDBNull(7) ? null : _database.Dates.ReadInstant(reader.GetString(7)),
            reader.GetInt32(8),
            scheduled,
            reader.IsDBNull(10) ? null : _database.Dates.ReadDay(reader.GetString(10)),
            reader.GetInt32(11) != 0,
            _database.Dates.ReadInstant(reader.GetString(12)),
            _database.Dates.ReadInstant(reader.GetString(13)));
    }

    void Insert(SqliteConnection connection, SqliteTransaction transaction, MemoItem item)
    {
        if (item.Type is not (MemoItemType.Task or MemoItemType.Note))
        {
            throw new PersistenceException("A memo type must be task or note.");
        }

        Execute(
            connection,
            transaction,
            """
            INSERT INTO memo_items (
                id, category_id, parent_id, type, title, body, is_completed, completed_at,
                sort_order, scheduled_date, due_date, is_archived, created_at, updated_at)
            VALUES (
                @id, @category, @parent, @type, @title, @body, @completed, @completedAt,
                @sort, @scheduled, @due, @archived, @created, @updated)
            """,
            RowParameters(item));
    }

    void Update(SqliteConnection connection, SqliteTransaction transaction, MemoItem item)
    {
        var changed = Execute(
            connection,
            transaction,
            """
            UPDATE memo_items
            SET category_id = @category, parent_id = @parent, type = @type, title = @title, body = @body,
                is_completed = @completed, completed_at = @completedAt, sort_order = @sort,
                scheduled_date = @scheduled, due_date = @due, is_archived = @archived, updated_at = @updated
            WHERE id = @id
            """,
            RowParameters(item));
        if (changed == 0)
        {
            throw new PersistenceException($"Memo {EntityId.Format(item.Id)} was not found.");
        }
    }

    (string Name, object Value)[] RowParameters(MemoItem item) =>
    [
        ("@id", EntityId.Format(item.Id)),
        ("@category", CategoryParameter(item.CategoryId)),
        ("@parent", item.ParentId is Guid parent ? EntityId.Format(parent) : DBNull.Value),
        ("@type", MemoTypeNames.ToStorage(item.Type)),
        ("@title", item.Title),
        ("@body", (object?)item.Body ?? DBNull.Value),
        ("@completed", item.IsCompleted ? 1 : 0),
        ("@completedAt", item.CompletedAt is DateTimeOffset completed ? _database.Dates.StoreInstant(completed) : DBNull.Value),
        ("@sort", item.SortOrder),
        ("@scheduled", _database.Dates.StoreDay(item.ScheduledDate)),
        ("@due", item.DueDate is DateOnly due ? _database.Dates.StoreDay(due) : DBNull.Value),
        ("@archived", item.IsArchived ? 1 : 0),
        ("@created", _database.Dates.StoreInstant(item.CreatedAt)),
        ("@updated", _database.Dates.StoreInstant(item.UpdatedAt))
    ];

    MemoItem? Find(SqliteConnection connection, SqliteTransaction transaction, Guid id)
    {
        var rows = Read(
            connection,
            transaction,
            "SELECT " + Columns + " FROM memo_items WHERE id = @id",
            ("@id", EntityId.Format(id)));
        return rows.Count == 0 ? null : rows[0];
    }

    int NextRootOrder(SqliteConnection connection, SqliteTransaction transaction, DateOnly day)
    {
        var (start, next) = _database.Dates.DayRange(day);
        using var command = SqliteCommand(connection, transaction, MemoSql.NextRootOrder);
        command.Parameters.AddWithValue("@start", start);
        command.Parameters.AddWithValue("@next", next);
        return Convert.ToInt32(command.ExecuteScalar(), System.Globalization.CultureInfo.InvariantCulture);
    }

    static int NextChildOrder(SqliteConnection connection, SqliteTransaction transaction, Guid parentId)
    {
        using var command = SqliteCommand(
            connection,
            transaction,
            "SELECT COALESCE(MAX(sort_order), -1) + 1 FROM memo_items WHERE parent_id = @parent");
        command.Parameters.AddWithValue("@parent", EntityId.Format(parentId));
        return Convert.ToInt32(command.ExecuteScalar(), System.Globalization.CultureInfo.InvariantCulture);
    }

    static object CategoryParameter(Guid? categoryId) =>
        categoryId is Guid id ? EntityId.Format(id) : DBNull.Value;

    static MemoItemType ParseType(string text) => text switch
    {
        MemoTypeNames.Task => MemoItemType.Task,
        MemoTypeNames.Note => MemoItemType.Note,
        _ => throw new PersistenceException($"Unknown memo type '{text}'.")
    };

    static string RequireTitle(string title)
    {
        var text = title.Trim();
        if (text.Length == 0)
        {
            throw new PersistenceException("A title is required.");
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
