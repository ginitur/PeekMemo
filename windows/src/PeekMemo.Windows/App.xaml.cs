using System.IO;
using System.Windows;
using PeekMemo.Core.Settings;
using PeekMemo.Windows.Services;
using PeekMemo.Windows.Settings;
using PeekMemo.Windows.Views;

namespace PeekMemo.Windows;

public partial class App : Application
{
    SingleInstance? _single;
    TrayIcon? _tray;
    EdgeWindow? _edge;
    SystemThemeWatcher? _theme;
    DisplayWatcher? _display;
    SettingsStore? _store;
    CurrentUserStartupRegistration? _startup;

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);
        _single = new SingleInstance();
        if (!_single.IsFirst)
        {
            _single.SignalShow();
            Shutdown();
            return;
        }

        var root = AppPaths.DefaultRoot();
        Directory.CreateDirectory(root);
        _store = new SettingsStore(root);
        var settings = _store.Load();
        _startup = new CurrentUserStartupRegistration();
        if (settings.LaunchAtStartup)
        {
            _startup.Apply(true, Environment.ProcessPath ?? "");
        }

        _edge = new EdgeWindow(_store, settings);
        _theme = new SystemThemeWatcher();
        _theme.Changed += () => Dispatcher.Invoke(RefreshFromDisk);
        _display = new DisplayWatcher();
        _display.Changed += () => Dispatcher.Invoke(() => _edge?.RevalidatePlacement());
        _single.WhenShowRequested(() => Dispatcher.Invoke(() => _edge?.ShowPinned()));
        _tray = new TrayIcon(
            show: () => Dispatcher.Invoke(() => _edge?.ShowPinned()),
            resetPosition: () => Dispatcher.Invoke(() => _edge?.ResetToPrimaryRight()),
            openSettings: () => Dispatcher.Invoke(OpenSettings),
            quit: () => Dispatcher.Invoke(Quit));
        _edge.Show();
    }

    void RefreshFromDisk()
    {
        if (_store is null)
        {
            return;
        }

        _edge?.ApplySettings(_store.Load());
    }

    void OpenSettings()
    {
        if (_store is null || _startup is null || _edge is null)
        {
            return;
        }

        var window = new SettingsWindow(_store, _store.Load(), _startup);
        window.Saved += saved => _edge.ApplySettings(saved);
        window.Show();
        window.Activate();
    }

    void Quit()
    {
        _edge?.AllowClose();
        Shutdown();
    }

    protected override void OnExit(ExitEventArgs e)
    {
        _theme?.Dispose();
        _display?.Dispose();
        _tray?.Dispose();
        _single?.Dispose();
        base.OnExit(e);
    }
}
