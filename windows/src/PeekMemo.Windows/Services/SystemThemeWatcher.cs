using Microsoft.Win32;

namespace PeekMemo.Windows.Services;

internal sealed class SystemThemeWatcher : IDisposable
{
    public event Action? Changed;

    public SystemThemeWatcher()
    {
        SystemEvents.UserPreferenceChanged += OnChanged;
    }

    public static bool AppsUseLightTheme()
    {
        using var key = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Themes\Personalize");
        return key?.GetValue("AppsUseLightTheme") is not int value || value != 0;
    }

    void OnChanged(object? sender, UserPreferenceChangedEventArgs e)
    {
        if (e.Category is UserPreferenceCategory.General or UserPreferenceCategory.Color)
        {
            Changed?.Invoke();
        }
    }

    public void Dispose()
    {
        SystemEvents.UserPreferenceChanged -= OnChanged;
    }
}
