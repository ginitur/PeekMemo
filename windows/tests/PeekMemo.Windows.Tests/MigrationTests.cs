using Microsoft.Data.Sqlite;
using PeekMemo.Core.Settings;
using PeekMemo.Persistence;
using Xunit;

namespace PeekMemo.Windows.Tests;

public class MigrationTests
{
    [Fact]
    public void FreshDatabaseSeedsTwoCategoriesAndNoMemos()
    {
        var root = PersistenceTestSupport.NewRoot();
        try
        {
            using var database = PersistenceTestSupport.Open(root);
            Assert.True(database.ForeignKeysEnabled());
            Assert.Equal(SchemaMigrator.InitialUserVersion, database.UserVersion());
            Assert.Equal(2, database.Count("categories"));
            Assert.Equal(0, database.Count("memo_items"));
            Assert.Equal(1, database.Count("schema_migrations"));

            var categories = database.Categories.ListActive();
            var work = Assert.Single(categories, category => category.Name == "Work");
            var personal = Assert.Single(categories, category => category.Name == "Personal");
            Assert.Equal("briefcase", work.Icon);
            Assert.Equal("house", personal.Icon);
            Assert.Equal(SchemaMigrator.Hex(0.20, 0.48, 0.96), work.Color);
            Assert.Equal(SchemaMigrator.Hex(0.20, 0.70, 0.45), personal.Color);
            Assert.Equal("#337AF5", work.Color);
            Assert.Equal("#33B273", personal.Color);
            Assert.DoesNotContain("Prepare report", database.Memos.ListAll().Select(item => item.Title));
            Assert.StartsWith(Path.GetTempPath(), PersistenceTestSupport.DatabasePath(root), StringComparison.OrdinalIgnoreCase);
            Assert.NotEqual(
                Path.GetFullPath(AppPaths.DatabaseFile(AppPaths.DefaultRoot())),
                Path.GetFullPath(PersistenceTestSupport.DatabasePath(root)));
        }
        finally
        {
            PersistenceTestSupport.Delete(root);
        }
    }

    [Fact]
    public void OpeningAgainDoesNotSeedASecondTime()
    {
        var root = PersistenceTestSupport.NewRoot();
        try
        {
            using (var first = PersistenceTestSupport.Open(root))
            {
                Assert.Equal(2, first.Count("categories"));
            }

            using var second = PersistenceTestSupport.Open(root);
            Assert.Equal(2, second.Count("categories"));
            Assert.Equal(0, second.Count("memo_items"));
        }
        finally
        {
            PersistenceTestSupport.Delete(root);
        }
    }

    [Fact]
    public void FailedMigrationLeavesTheDatabaseFileInPlace()
    {
        var root = PersistenceTestSupport.NewRoot();
        try
        {
            var path = PersistenceTestSupport.DatabasePath(root);
            using (var database = PersistenceTestSupport.Open(root))
            {
                Assert.Equal(2, database.Count("categories"));
            }

            using (var connection = new SqliteConnection(new SqliteConnectionStringBuilder
            {
                DataSource = path,
                Pooling = false
            }.ConnectionString))
            {
                connection.Open();
                using var command = connection.CreateCommand();
                command.CommandText = "DROP TABLE schema_migrations";
                command.ExecuteNonQuery();
            }

            var before = File.ReadAllBytes(path);
            var error = Assert.Throws<PersistenceException>(() => PersistenceTestSupport.Open(root));
            Assert.Contains("not deleted", error.Message, StringComparison.OrdinalIgnoreCase);
            Assert.True(File.Exists(path));
            Assert.Equal(before, File.ReadAllBytes(path));

            using var check = new SqliteConnection(new SqliteConnectionStringBuilder
            {
                DataSource = path,
                Pooling = false
            }.ConnectionString);
            check.Open();
            using var names = check.CreateCommand();
            names.CommandText = "SELECT name FROM categories ORDER BY sort_order";
            using var reader = names.ExecuteReader();
            Assert.True(reader.Read());
            Assert.Equal("Work", reader.GetString(0));
            Assert.True(reader.Read());
            Assert.Equal("Personal", reader.GetString(0));
        }
        finally
        {
            PersistenceTestSupport.Delete(root);
        }
    }
}
