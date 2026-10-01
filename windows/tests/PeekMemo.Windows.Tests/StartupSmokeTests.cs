using PeekMemo.Core.Settings;
using PeekMemo.Persistence;
using Xunit;

namespace PeekMemo.Windows.Tests;

public class StartupSmokeTests
{
    [Fact]
    public void SmokeLeavesWorkPersonalSettingsAndNoMemoRows()
    {
        var root = PersistenceTestSupport.NewRoot();
        try
        {
            StartupSmoke.Run(root);

            using var database = PersistenceTestSupport.Open(root);
            Assert.Equal(2, database.Count("categories"));
            Assert.Equal(0, database.Count("memo_items"));
            Assert.Contains(database.Categories.ListActive(), category => category.Name == "Work");
            Assert.Contains(database.Categories.ListActive(), category => category.Name == "Personal");
            Assert.True(File.Exists(AppPaths.SettingsFile(root)));
            Assert.StartsWith(Path.GetTempPath(), root, StringComparison.OrdinalIgnoreCase);
        }
        finally
        {
            PersistenceTestSupport.Delete(root);
        }
    }
}
