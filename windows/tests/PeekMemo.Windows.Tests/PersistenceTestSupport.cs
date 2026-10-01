using PeekMemo.Persistence;

namespace PeekMemo.Windows.Tests;

static class PersistenceTestSupport
{
    public static readonly DateOnly Today = new(2026, 10, 1);
    public static readonly DateTimeOffset At = new(2026, 10, 1, 15, 0, 0, TimeSpan.Zero);
    public static readonly TimeZoneInfo Zone = TimeZoneInfo.CreateCustomTimeZone(
        "PeekMemoMinus7",
        TimeSpan.FromHours(-7),
        "PeekMemoMinus7",
        "PeekMemoMinus7");

    public static string NewRoot()
    {
        var path = Path.Combine(Path.GetTempPath(), "peekmemo-tests", Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(path);
        return path;
    }

    public static MemoDatabase Open(string root) =>
        MemoDatabase.Open(DatabasePath(root), Zone, () => At);

    public static string DatabasePath(string root) => Path.Combine(root, "PeekMemo.sqlite");

    public static void Delete(string root)
    {
        if (Directory.Exists(root))
        {
            Directory.Delete(root, recursive: true);
        }
    }
}
