namespace PeekMemo.Core.Settings;

/// Per-user startup. The Windows app writes one HKCU Run value. It does not touch HKLM and does not need admin.
public static class StartupRegistration
{
    public const string ValueName = "PeekMemo";
    public const string RunKeyPath = @"Software\Microsoft\Windows\CurrentVersion\Run";

    public static string QuoteCommand(string executablePath)
    {
        if (executablePath.Length == 0)
        {
            return executablePath;
        }

        return executablePath.Contains(' ', StringComparison.Ordinal)
            ? $"\"{executablePath}\""
            : executablePath;
    }
}

public interface IStartupRegistration
{
    void Apply(bool enabled, string executablePath);
}
