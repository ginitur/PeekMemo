using PeekMeow.Core.Settings;

namespace PeekMeow.Persistence;

/// Non-interactive check used by the published executable. It never touches the real data directory.
public static class StartupSmoke
{
    public static void Run(string root)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(root);
        Directory.CreateDirectory(root);
        var databasePath = AppPaths.DatabaseFile(root);
        using (var database = MemoDatabase.Open(databasePath))
        {
            var categories = database.Categories.ListActive();
            if (categories.Count != 2
                || categories.All(category => category.Name != "Work")
                || categories.All(category => category.Name != "Personal"))
            {
                throw new PersistenceException("A fresh database did not contain Work and Personal.");
            }

            if (database.Memos.ListAll().Count != 0)
            {
                throw new PersistenceException("A fresh database contained memo rows.");
            }
        }

        var settings = new SettingsStore(root);
        settings.Save(new AppSettings());
        _ = settings.Load();
    }
}
