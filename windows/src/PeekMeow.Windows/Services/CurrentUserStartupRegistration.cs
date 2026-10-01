using Microsoft.Win32;
using PeekMeow.Core.Settings;

namespace PeekMeow.Windows.Services;

/// Writes a single HKCU Run value. Business data stays in settings.json, not the registry.
internal sealed class CurrentUserStartupRegistration : IStartupRegistration
{
    public void Apply(bool enabled, string executablePath)
    {
        using var key = Registry.CurrentUser.CreateSubKey(StartupRegistration.RunKeyPath, writable: true);
        if (key is null)
        {
            return;
        }

        if (!enabled || string.IsNullOrWhiteSpace(executablePath))
        {
            key.DeleteValue(StartupRegistration.ValueName, throwOnMissingValue: false);
            return;
        }

        key.SetValue(StartupRegistration.ValueName, StartupRegistration.QuoteCommand(executablePath));
    }
}
