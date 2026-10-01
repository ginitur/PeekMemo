using Microsoft.Win32;

namespace PeekMemo.Windows.Services;

/// Display, DPI, and work-area changes. This is not a timer.
internal sealed class DisplayWatcher : IDisposable
{
    public event Action? Changed;

    public DisplayWatcher()
    {
        SystemEvents.DisplaySettingsChanged += OnDisplay;
        SystemEvents.UserPreferenceChanged += OnPreference;
    }

    public void Dispose()
    {
        SystemEvents.DisplaySettingsChanged -= OnDisplay;
        SystemEvents.UserPreferenceChanged -= OnPreference;
    }

    void OnDisplay(object? sender, EventArgs e) => Changed?.Invoke();

    void OnPreference(object? sender, UserPreferenceChangedEventArgs e)
    {
        if (e.Category == UserPreferenceCategory.Desktop)
        {
            Changed?.Invoke();
        }
    }
}
