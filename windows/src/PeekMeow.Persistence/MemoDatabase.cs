using Microsoft.Data.Sqlite;
using PeekMeow.Core.Models;

namespace PeekMeow.Persistence;

public sealed class MemoDatabase : IDisposable
{
    readonly SqliteConnection _connection;
    readonly object _gate = new();
    bool _disposed;

    MemoDatabase(SqliteConnection connection, DateStorageMapper dates, Func<DateTimeOffset> clock)
    {
        _connection = connection;
        Dates = dates;
        Clock = clock;
        Categories = new SqliteCategoryRepository(this);
        Memos = new SqliteMemoRepository(this);
    }

    public DateStorageMapper Dates { get; }
    public Func<DateTimeOffset> Clock { get; }
    public ICategoryRepository Categories { get; }
    public IMemoRepository Memos { get; }

    public static MemoDatabase Open(string path, TimeZoneInfo? zone = null, Func<DateTimeOffset>? clock = null)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(path);
        var directory = Path.GetDirectoryName(path);
        if (!string.IsNullOrEmpty(directory))
        {
            Directory.CreateDirectory(directory);
        }

        var builder = new SqliteConnectionStringBuilder
        {
            DataSource = path,
            Mode = SqliteOpenMode.ReadWriteCreate,
            Pooling = false
        };
        var connection = new SqliteConnection(builder.ConnectionString);
        MemoDatabase? database = null;
        try
        {
            connection.Open();
            using (var pragma = connection.CreateCommand())
            {
                pragma.CommandText = "PRAGMA foreign_keys = ON";
                pragma.ExecuteNonQuery();
            }

            var dates = new DateStorageMapper(zone ?? TimeZoneInfo.Local);
            var now = clock ?? (() => DateTimeOffset.UtcNow);
            database = new MemoDatabase(connection, dates, now);
            SchemaMigrator.Apply(connection, dates, now);
            return database;
        }
        catch
        {
            database?.Dispose();
            if (database is null)
            {
                connection.Dispose();
            }

            throw;
        }
    }

    public T Read<T>(Func<SqliteConnection, T> work)
    {
        ObjectDisposedException.ThrowIf(_disposed, this);
        lock (_gate)
        {
            return work(_connection);
        }
    }

    public void Write(Action<SqliteConnection, SqliteTransaction> work)
    {
        ObjectDisposedException.ThrowIf(_disposed, this);
        lock (_gate)
        {
            using var transaction = _connection.BeginTransaction();
            try
            {
                work(_connection, transaction);
                transaction.Commit();
            }
            catch
            {
                try
                {
                    transaction.Rollback();
                }
                catch (InvalidOperationException)
                {
                }

                throw;
            }
        }
    }

    public int Count(string table)
    {
        if (table is not ("categories" or "memo_items" or "schema_migrations"))
        {
            throw new ArgumentOutOfRangeException(nameof(table));
        }

        return Read(connection =>
        {
            using var command = connection.CreateCommand();
            command.CommandText = $"SELECT COUNT(*) FROM {table}";
            return Convert.ToInt32(command.ExecuteScalar(), System.Globalization.CultureInfo.InvariantCulture);
        });
    }

    public bool ForeignKeysEnabled() =>
        Read(connection =>
        {
            using var command = connection.CreateCommand();
            command.CommandText = "PRAGMA foreign_keys";
            return Convert.ToInt32(command.ExecuteScalar(), System.Globalization.CultureInfo.InvariantCulture) == 1;
        });

    public int UserVersion() => Read(SchemaMigrator.UserVersion);

    public void Dispose()
    {
        if (_disposed)
        {
            return;
        }

        _disposed = true;
        _connection.Dispose();
    }
}
