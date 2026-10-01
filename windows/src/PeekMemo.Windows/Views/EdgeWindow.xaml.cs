using System.ComponentModel;
using System.Windows;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Threading;
using PeekMemo.Core.Hover;
using PeekMemo.Core.Layout;
using PeekMemo.Core.Settings;
using PeekMemo.Windows.Services;
using PeekMemo.Windows.ViewModels;
using PeekMemo.Windows.Windowing;

namespace PeekMemo.Windows.Views;

public partial class EdgeWindow : NonActivatingWindow
{
    readonly EdgeSession _session;
    readonly SettingsStore _store;
    readonly DispatcherTimer _timer;
    bool _allowClose;
    bool _monitorSaved;

    public EdgeWindow(SettingsStore store, AppSettings settings)
    {
        InitializeComponent();
        _store = store;
        _session = new EdgeSession(settings);
        _timer = new DispatcherTimer();
        _timer.Tick += (_, _) => OnTimer();
        ApplyChrome();
        ApplyFrame();
    }

    public void ApplySettings(AppSettings settings)
    {
        _session.ReplaceSettings(settings);
        ApplyChrome();
        ApplyFrame();
    }

    public void ShowPinned()
    {
        _session.Hover.ShowPinned();
        ApplyFrame();
        if (!IsVisible)
        {
            Show();
        }
    }

    public void AllowClose() => _allowClose = true;

    protected override void OnMouseEnter(System.Windows.Input.MouseEventArgs e)
    {
        base.OnMouseEnter(e);
        _session.Hover.PointerEntered(DateTimeOffset.Now);
        Advance();
    }

    protected override void OnMouseLeave(System.Windows.Input.MouseEventArgs e)
    {
        base.OnMouseLeave(e);
        _session.Hover.PointerLeft(DateTimeOffset.Now);
        Advance();
    }

    protected override void OnPreviewMouseLeftButtonDown(MouseButtonEventArgs e)
    {
        _session.Hover.TogglePin();
        ApplyFrame();
        e.Handled = true;
    }

    protected override void OnClosing(CancelEventArgs e)
    {
        if (!_allowClose)
        {
            e.Cancel = true;
            return;
        }

        base.OnClosing(e);
    }

    void OnTimer()
    {
        _timer.Stop();
        Advance();
    }

    void Advance()
    {
        _session.Hover.Tick(DateTimeOffset.Now);
        ApplyFrame();
        Schedule();
    }

    void Schedule()
    {
        _timer.Stop();
        if (_session.Hover.NextTransitionAt is not DateTimeOffset due)
        {
            return;
        }

        var delay = due - DateTimeOffset.Now;
        _timer.Interval = delay <= TimeSpan.Zero ? TimeSpan.FromMilliseconds(1) : delay;
        _timer.Start();
    }

    void ApplyFrame()
    {
        var area = NativeMonitor.Primary();
        if (area is null)
        {
            return;
        }

        RememberMonitor(area.Value);
        var frame = _session.FrameFor(area.Value.Bounds);
        Left = frame.X;
        Top = frame.Y;
        Width = Math.Max(1, frame.Width);
        Height = Math.Max(1, frame.Height);
        var open = _session.Hover.Phase is HoverPhase.Expanded or HoverPhase.Pinned;
        ExpandedChrome.Margin = new Thickness(0, 0, LayoutMetrics.HitThickness, 0);
        CollapsedChrome.Visibility = open ? Visibility.Collapsed : Visibility.Visible;
        ExpandedChrome.Visibility = open ? Visibility.Visible : Visibility.Collapsed;
    }

    void RememberMonitor(ScreenWorkArea area)
    {
        if (_monitorSaved || string.IsNullOrWhiteSpace(area.DeviceName))
        {
            return;
        }

        if (!string.IsNullOrWhiteSpace(_session.Settings.MonitorDeviceName))
        {
            _monitorSaved = true;
            return;
        }

        _session.Settings.MonitorDeviceName = area.DeviceName;
        _store.Save(_session.Settings);
        _monitorSaved = true;
    }

    void ApplyChrome()
    {
        var settings = _session.Settings;
        var light = settings.ResolvedTheme() switch
        {
            ThemePreference.Light => true,
            ThemePreference.Dark => false,
            _ => SystemThemeWatcher.AppsUseLightTheme()
        };
        var card = light ? Color.FromRgb(247, 247, 248) : Color.FromRgb(44, 44, 46);
        var ink = light ? Color.FromRgb(28, 28, 30) : Color.FromRgb(245, 245, 247);
        var line = light ? Color.FromArgb(48, 0, 0, 0) : Color.FromArgb(64, 255, 255, 255);
        var opacity = Math.Clamp(settings.PanelOpacity, 0.70, 1);
        ExpandedChrome.Background = new SolidColorBrush(Color.FromArgb((byte)Math.Round(255 * opacity), card.R, card.G, card.B));
        ExpandedChrome.BorderBrush = new SolidColorBrush(line);
        TitleText.Foreground = new SolidColorBrush(ink);
        SubtitleText.Foreground = new SolidColorBrush(ink);
        CollapsedChrome.Width = Math.Clamp(settings.WedgeThickness, 2, 6);
        CollapsedChrome.Opacity = Math.Clamp(settings.WedgeOpacity, 0.2, 1);
        CollapsedChrome.Background = new SolidColorBrush(light ? Color.FromRgb(72, 128, 176) : Color.FromRgb(142, 184, 220));
    }
}
