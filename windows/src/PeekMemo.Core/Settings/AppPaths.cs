namespace PeekMemo.Core.Settings;

public static class AppPaths
{
    public static string DefaultRoot() =>
        Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "PeekMemo");

    public static string SettingsFile(string root) => Path.Combine(root, "settings.json");

    public static string InstanceFile(string root) => Path.Combine(root, "instance.json");

    public static string DatabaseFile(string root) => Path.Combine(root, "PeekMemo.sqlite");

    public static string BackgroundsDirectory(string root) => Path.Combine(root, "Backgrounds");
}
