using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Windows;
using PeekMemo.Core.Settings;
using PeekMemo.Persistence;
using PeekMemo.Windows.Services;
using PeekMemo.Windows.Settings;
using PeekMemo.Windows.Views;

namespace PeekMemo.Windows;

public partial class App : Application
{
    SingleInstance? _single;
    string? _instanceFile;
    TrayIcon? _tray;
    EdgeWindow? _edge;
    SystemThemeWatcher? _theme;
    DisplayWatcher? _display;
    SettingsStore? _store;
    CurrentUserStartupRegistration? _startup;
    MemoDatabase? _database;

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);
        if (e.Args.Any(argument => argument == "--version"))
        {
            ConsoleAttach.Write(BuildIdentity.Report);
            Environment.Exit(0);
            return;
        }

        if (e.Args.Any(argument => argument == "--diagnose"))
        {
            ConsoleAttach.Write(ReleaseDiagnostics.Describe());
            Environment.Exit(0);
            return;
        }

        if (e.Args.Any(argument => argument == "--smoke"))
        {
            Environment.Exit(RunSmoke());
            return;
        }

        if (e.Args.Any(argument => argument == "--smoke-ui"))
        {
            Environment.Exit(ReleaseDiagnostics.RunSmokeUi());
            return;
        }

        if (e.Args.Any(argument => argument == "--diagnose-ui"))
        {
            StartDiagnoseUi();
            return;
        }

        _single = new SingleInstance();
        if (!_single.IsFirst)
        {
            var decision = InstanceHandoff.Decide(AppPaths.InstanceFile(AppPaths.DefaultRoot()), BuildIdentity.Version);
            if (decision.Signal)
            {
                _single.SignalShow();
            }
            else
            {
                MessageBox.Show(decision.Refusal, "PeekMemo", MessageBoxButton.OK, MessageBoxImage.Warning);
            }

            Shutdown();
            return;
        }

        var root = AppPaths.DefaultRoot();
        Directory.CreateDirectory(root);
        _instanceFile = AppPaths.InstanceFile(root);
        try
        {
            InstanceHandoff.Publish(_instanceFile, BuildIdentity.Version, BuildIdentity.Commit);
        }
        catch (Exception exception)
        {
            Trace.TraceError("[Persistence] {0}", exception);
        }
        _store = new SettingsStore(root);
        var settings = _store.Load();
        _startup = new CurrentUserStartupRegistration();
        if (settings.LaunchAtStartup)
        {
            _startup.Apply(true, Environment.ProcessPath ?? "");
        }

        try
        {
            _database = MemoDatabase.Open(AppPaths.DatabaseFile(root));
        }
        catch (Exception exception)
        {
            Trace.TraceError("[Persistence] {0}", exception);
            _database = null;
        }

        _edge = new EdgeWindow(_store, settings, _database);
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
        window.Preview += preview => _edge.PreviewAppearance(preview);
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
        if (_instanceFile is not null)
        {
            InstanceHandoff.RemoveIfOurs(_instanceFile);
        }

        _single?.Dispose();
        _database?.Dispose();
        base.OnExit(e);
    }

    void StartDiagnoseUi()
    {
        var root = Path.Combine(Path.GetTempPath(), "peekmemo-diagnose-ui", Guid.NewGuid().ToString("N"));
        try
        {
            Directory.CreateDirectory(root);
            var store = new SettingsStore(root);
            var settings = store.Load();
            _database = MemoDatabase.Open(AppPaths.DatabaseFile(root));
            _edge = new EdgeWindow(store, settings, _database);
            _edge.Show();
            _edge.ShowPinned();
            Dispatcher.BeginInvoke(new Action(() =>
            {
                try
                {
                    var report = BuildIdentity.Report + "\n" + _edge?.DescribeInterface(openCategoryMenu: true);
                    ConsoleAttach.Write(report);
                    _edge?.AllowClose();
                    Shutdown(0);
                }
                catch (Exception exception)
                {
                    ConsoleAttach.Write(exception.ToString());
                    Shutdown(1);
                }
                finally
                {
                    try
                    {
                        if (Directory.Exists(root))
                        {
                            Directory.Delete(root, recursive: true);
                        }
                    }
                    catch (Exception exception)
                    {
                        Trace.TraceError("[Persistence] {0}", exception);
                    }
                }
            }), System.Windows.Threading.DispatcherPriority.ContextIdle);
        }
        catch (Exception exception)
        {
            ConsoleAttach.Write(exception.ToString());
            Environment.Exit(1);
        }
    }

    static int RunSmoke()
    {
        var root = Path.Combine(Path.GetTempPath(), "peekmemo-smoke", Guid.NewGuid().ToString("N"));
        try
        {
            StartupSmoke.Run(root);
            return 0;
        }
        catch (Exception exception)
        {
            Trace.TraceError("[Persistence] {0}", exception);
            return 1;
        }
        finally
        {
            try
            {
                if (Directory.Exists(root))
                {
                    Directory.Delete(root, recursive: true);
                }
            }
            catch (Exception exception)
            {
                Trace.TraceError("[Persistence] {0}", exception);
            }
        }
    }
}
