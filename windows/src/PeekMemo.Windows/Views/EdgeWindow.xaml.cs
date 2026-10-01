using System.Collections.Generic;
using System.ComponentModel;
using System.Windows;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Threading;
using PeekMemo.Core.Geometry;
using CoreDpi = PeekMemo.Core.Geometry.DpiScale;
using PeekMemo.Core.Hover;
using PeekMemo.Core.Layout;
using PeekMemo.Core.Models;
using PeekMemo.Core.Settings;
using PeekMemo.Windows.Services;
using PeekMemo.Windows.ViewModels;
using PeekMemo.Windows.Windowing;

namespace PeekMemo.Windows.Views;

public partial class EdgeWindow : NonActivatingWindow
{
    enum PressKind
    {
        None,
        DragCandidate,
        Click,
        Resize
    }

    readonly EdgeSession _session;
    readonly SettingsStore _store;
    readonly DispatcherTimer _timer;
    PlacementLayout _layout;
    MonitorDescriptor _monitor;
    bool _hasMonitor;
    bool _allowClose;
    bool _hoverInside;
    bool _dragging;
    bool _resizing;
    PressKind _press;
    int _pressX;
    int _pressY;
    uint _pressDpi;
    int _resizeOriginX;
    int _resizeOriginY;
    double _resizeStartWidth;
    double _resizeStartHeight;

    public EdgeWindow(SettingsStore store, AppSettings settings)
    {
        InitializeComponent();
        _store = store;
        _session = new EdgeSession(settings);
        _timer = new DispatcherTimer();
        _timer.Tick += (_, _) => OnTimer();
        ApplyChrome();
        ApplyFrame();
        Loaded += (_, _) => RevalidatePlacement();
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

    public void ResetToPrimaryRight()
    {
        EndGestureWithoutCommit();
        var monitors = MonitorsOrWindow();
        if (monitors.Count == 0)
        {
            return;
        }

        var primary = MonitorMigration.Primary(monitors);
        var offset = primary.WorkingArea.Height / 2;
        _session.Settings.WriteAnchor(new EdgeAnchor(primary.DeviceName, ScreenEdge.Right, offset));
        _store.Save(_session.Settings);
        _session.Hover.ShowPinned();
        ApplyFrame();
        if (!IsVisible)
        {
            Show();
        }
    }

    public void AllowClose() => _allowClose = true;

    public void RevalidatePlacement()
    {
        if (_dragging || _resizing)
        {
            ApplyFrame();
            return;
        }

        var monitors = MonitorsOrWindow();
        if (monitors.Count > 0)
        {
            PersistPlacement(monitors);
        }

        ApplyFrame();
    }

    protected override void OnSourceInitialized(EventArgs e)
    {
        base.OnSourceInitialized(e);
        RevalidatePlacement();
    }

    protected override void OnDisplayMetricsChanged() => RevalidatePlacement();

    protected override void OnMouseEnter(MouseEventArgs e)
    {
        base.OnMouseEnter(e);
        TrackPointer(e);
    }

    protected override void OnMouseLeave(MouseEventArgs e)
    {
        base.OnMouseLeave(e);
        if (_dragging || _resizing)
        {
            return;
        }

        SetHoverInside(false);
        Cursor = Cursors.Arrow;
    }

    protected override void OnPreviewMouseMove(MouseEventArgs e)
    {
        base.OnPreviewMouseMove(e);
        TrackPointer(e);
    }

    protected override void OnPreviewMouseLeftButtonDown(MouseButtonEventArgs e)
    {
        if (!_hasMonitor || !NativeMonitor.TryCursor(out var x, out var y))
        {
            return;
        }

        var dip = DipOnMonitor(_monitor, x, y);
        var expanded = IsVisuallyExpanded;
        _pressX = x;
        _pressY = y;
        _pressDpi = _monitor.Dpi == 0 ? 96 : _monitor.Dpi;
        if (expanded && PanelResizeGeometry.BeginsResize(dip.X, dip.Y, _layout.ContentFrame, _layout.Anchor.Edge))
        {
            _press = PressKind.Resize;
            _resizing = true;
            _resizeOriginX = x;
            _resizeOriginY = y;
            _resizeStartWidth = _session.LiveWidth;
            _resizeStartHeight = _session.LiveHeight;
            _session.Interaction.BeginResize();
            _timer.Stop();
            CaptureMouse();
            e.Handled = true;
            return;
        }

        if (DragHandleGeometry.Rect(_layout, expanded, WedgeLength, LayoutMetrics.HitThickness).ContainsPoint(dip.X, dip.Y))
        {
            _press = PressKind.DragCandidate;
            CaptureMouse();
            e.Handled = true;
            return;
        }

        _press = PressKind.Click;
        CaptureMouse();
        e.Handled = true;
    }

    protected override void OnPreviewMouseLeftButtonUp(MouseButtonEventArgs e)
    {
        var kind = _press;
        var dragged = _dragging;
        var resized = _resizing;
        if (dragged)
        {
            FinishDrag();
        }
        else if (resized)
        {
            FinishResize();
        }
        else if (kind is PressKind.DragCandidate or PressKind.Click)
        {
            _session.Hover.TogglePin();
            ApplyFrame();
        }

        _press = PressKind.None;
        if (IsMouseCaptured)
        {
            ReleaseMouseCapture();
        }

        Advance();
        e.Handled = true;
    }

    protected override void OnLostMouseCapture(MouseEventArgs e)
    {
        base.OnLostMouseCapture(e);
        if (_dragging)
        {
            FinishDrag();
        }
        else if (_resizing)
        {
            FinishResize();
        }

        _press = PressKind.None;
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

    void TrackPointer(MouseEventArgs e)
    {
        if (!NativeMonitor.TryCursor(out var x, out var y))
        {
            return;
        }

        if (_press == PressKind.DragCandidate && e.LeftButton == MouseButtonState.Pressed)
        {
            MaybeStartDrag(x, y);
        }

        if (_dragging)
        {
            ApplyFrame();
            Cursor = Cursors.SizeAll;
            return;
        }

        if (_resizing)
        {
            ApplyResize(x, y);
            return;
        }

        if (!_hasMonitor)
        {
            return;
        }

        var dip = DipOnMonitor(_monitor, x, y);
        var expanded = IsVisuallyExpanded;
        SetHoverInside(HitHover(dip, expanded));
        UpdateCursor(dip, expanded);
    }

    void MaybeStartDrag(int x, int y)
    {
        var limit = new CoreDpi(_pressDpi).ToPixels(LayoutMetrics.DragThreshold);
        var dx = x - _pressX;
        var dy = y - _pressY;
        if (dx * (long)dx + dy * (long)dy < (long)limit * limit)
        {
            return;
        }

        _dragging = true;
        _press = PressKind.None;
        _session.Interaction.BeginDrag();
        _timer.Stop();
        SetHoverInside(true);
        ApplyFrame();
    }

    void FinishDrag()
    {
        if (!_dragging)
        {
            return;
        }

        _dragging = false;
        if (NativeMonitor.TryCursor(out var x, out var y))
        {
            var monitor = NativeMonitor.FromPoint(x, y) ?? _monitor;
            var dip = DipOnMonitor(monitor, x, y);
            var sample = DragGeometry.Commit(dip.X, dip.Y, monitor.WorkingArea, WedgeLength, LayoutMetrics.HitThickness);
            _session.Settings.WriteAnchor(new EdgeAnchor(monitor.DeviceName, sample.Edge, sample.Offset));
            _store.Save(_session.Settings);
        }

        _session.Interaction.EndDrag(DateTimeOffset.Now);
        ApplyFrame();
        SyncHover();
    }

    void ApplyResize(int x, int y)
    {
        if (!_hasMonitor)
        {
            return;
        }

        var scale = _monitor.Scale.Factor;
        var dx = (x - _resizeOriginX) / scale;
        var dy = (y - _resizeOriginY) / scale;
        var requested = ResizeGeometry.Requested(
            _resizeStartWidth,
            _resizeStartHeight,
            dx,
            dy,
            _layout.Anchor.Edge);
        _session.SetLiveSize(requested.Width, requested.Height);
        ApplyFrame();
        Cursor = ResizeCursor(_layout.Anchor.Edge);
    }

    void FinishResize()
    {
        if (!_resizing)
        {
            return;
        }

        _resizing = false;
        var stored = ResizeGeometry.ForStore(_session.LiveWidth, _session.LiveHeight);
        _session.SetLiveSize(stored.Width, stored.Height);
        _session.Settings.WritePanelSize(stored.Width, stored.Height);
        _store.Save(_session.Settings);
        _session.Interaction.EndResize(DateTimeOffset.Now);
        ApplyFrame();
        SyncHover();
    }

    void EndGestureWithoutCommit()
    {
        if (_dragging)
        {
            _dragging = false;
            _session.Interaction.EndDrag(DateTimeOffset.Now);
        }

        if (_resizing)
        {
            _resizing = false;
            _session.Interaction.EndResize(DateTimeOffset.Now);
        }

        _press = PressKind.None;
        if (IsMouseCaptured)
        {
            ReleaseMouseCapture();
        }
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
        if (_dragging || _resizing || _session.Hover.NextTransitionAt is not DateTimeOffset due)
        {
            return;
        }

        var delay = due - DateTimeOffset.Now;
        _timer.Interval = delay <= TimeSpan.Zero ? TimeSpan.FromMilliseconds(1) : delay;
        _timer.Start();
    }

    void SyncHover()
    {
        if (!_hasMonitor || !NativeMonitor.TryCursor(out var x, out var y))
        {
            SetHoverInside(false);
            return;
        }

        SetHoverInside(HitHover(DipOnMonitor(_monitor, x, y), IsVisuallyExpanded));
    }

    bool HitHover(DipPoint dip, bool expanded)
    {
        if (expanded)
        {
            return HoverRegions.For(_layout, expanded: true).Contains(dip.X, dip.Y);
        }

        if (!IsMouseCaptured)
        {
            return true;
        }

        return _layout.CollapsedFrame.ContainsPoint(dip.X, dip.Y);
    }

    void SetHoverInside(bool inside)
    {
        if (_dragging || _resizing)
        {
            inside = true;
        }

        if (inside == _hoverInside)
        {
            return;
        }

        _hoverInside = inside;
        var now = DateTimeOffset.Now;
        if (inside)
        {
            _session.Hover.PointerEntered(now);
        }
        else
        {
            _session.Hover.PointerLeft(now);
        }

        Advance();
    }

    void ApplyFrame()
    {
        if (_dragging && NativeMonitor.TryCursor(out var dragX, out var dragY))
        {
            var dragged = NativeMonitor.FromPoint(dragX, dragY) ?? _monitor;
            if (_hasMonitor || !string.IsNullOrWhiteSpace(dragged.DeviceName))
            {
                var dip = DipOnMonitor(dragged, dragX, dragY);
                var sample = DragGeometry.Live(dip.X, dip.Y, dragged.WorkingArea, WedgeLength, LayoutMetrics.HitThickness);
                _monitor = dragged;
                _hasMonitor = true;
                Remember(dragged, sample.Frame);
                ShowChrome(expanded: false, sample.Edge, sample.Frame);
                return;
            }
        }

        var monitors = MonitorsOrWindow();
        if (monitors.Count == 0)
        {
            return;
        }

        var monitor = SelectMonitor(monitors);
        var anchor = _session.Settings.ResolveAnchor(monitor.WorkingArea);
        anchor = new EdgeAnchor(monitor.DeviceName, anchor.Edge, anchor.Offset);
        var layout = PlacementLayout.Create(
            anchor,
            monitor.WorkingArea,
            _session.LiveWidth,
            _session.LiveHeight,
            WedgeLength);
        _layout = layout;
        _monitor = monitor;
        _hasMonitor = true;
        var expanded = IsVisuallyExpanded;
        var frame = expanded ? layout.ExpandedFrame : layout.CollapsedFrame;
        Remember(monitor, frame);
        ShowChrome(expanded, layout.Anchor.Edge, frame);
    }

    void ShowChrome(bool expanded, ScreenEdge edge, DipRect frame)
    {
        var settings = _session.Settings;
        var thickness = Math.Clamp(settings.WedgeThickness, 2, 6);
        CollapsedChrome.Visibility = expanded ? Visibility.Collapsed : Visibility.Visible;
        ExpandedChrome.Visibility = expanded ? Visibility.Visible : Visibility.Collapsed;
        DragHandleChrome.Visibility = expanded ? Visibility.Visible : Visibility.Collapsed;
        ResizeGrip.Visibility = expanded ? Visibility.Visible : Visibility.Collapsed;
        SubtitleText.Text = edge switch
        {
            ScreenEdge.Left => "Left edge",
            ScreenEdge.Bottom => "Bottom edge",
            _ => "Right edge"
        };

        if (edge == ScreenEdge.Bottom)
        {
            CollapsedChrome.HorizontalAlignment = HorizontalAlignment.Stretch;
            CollapsedChrome.VerticalAlignment = VerticalAlignment.Bottom;
            CollapsedChrome.Width = double.NaN;
            CollapsedChrome.Height = thickness;
            DragHandleMark.HorizontalAlignment = HorizontalAlignment.Stretch;
            DragHandleMark.VerticalAlignment = VerticalAlignment.Bottom;
            DragHandleMark.Width = double.NaN;
            DragHandleMark.Height = thickness;
            ExpandedChrome.Margin = new Thickness(0, 0, 0, LayoutMetrics.HitThickness);
        }
        else
        {
            var onLeft = edge == ScreenEdge.Left;
            CollapsedChrome.HorizontalAlignment = onLeft ? HorizontalAlignment.Left : HorizontalAlignment.Right;
            CollapsedChrome.VerticalAlignment = VerticalAlignment.Stretch;
            CollapsedChrome.Width = thickness;
            CollapsedChrome.Height = double.NaN;
            DragHandleMark.HorizontalAlignment = onLeft ? HorizontalAlignment.Left : HorizontalAlignment.Right;
            DragHandleMark.VerticalAlignment = VerticalAlignment.Stretch;
            DragHandleMark.Width = thickness;
            DragHandleMark.Height = double.NaN;
            ExpandedChrome.Margin = onLeft
                ? new Thickness(LayoutMetrics.HitThickness, 0, 0, 0)
                : new Thickness(0, 0, LayoutMetrics.HitThickness, 0);
        }

        if (expanded && _hasMonitor)
        {
            var handle = DragHandleGeometry.Rect(_layout, expanded: true, WedgeLength, LayoutMetrics.HitThickness);
            DragHandleChrome.Width = Math.Max(1, handle.Width);
            DragHandleChrome.Height = Math.Max(1, handle.Height);
            DragHandleChrome.Margin = new Thickness(handle.X - frame.X, handle.Y - frame.Y, 0, 0);
        }

        switch (edge)
        {
            case ScreenEdge.Left:
                ResizeGrip.HorizontalAlignment = HorizontalAlignment.Right;
                ResizeGrip.VerticalAlignment = VerticalAlignment.Bottom;
                ResizeGrip.Margin = new Thickness(0, 0, PanelResizeGeometry.GripInset, PanelResizeGeometry.GripInset);
                ResizeGrip.RenderTransform = Transform.Identity;
                break;
            case ScreenEdge.Bottom:
                ResizeGrip.HorizontalAlignment = HorizontalAlignment.Right;
                ResizeGrip.VerticalAlignment = VerticalAlignment.Top;
                ResizeGrip.Margin = new Thickness(0, PanelResizeGeometry.GripInset, PanelResizeGeometry.GripInset, 0);
                ResizeGrip.RenderTransform = new RotateTransform(-90);
                break;
            default:
                ResizeGrip.HorizontalAlignment = HorizontalAlignment.Left;
                ResizeGrip.VerticalAlignment = VerticalAlignment.Bottom;
                ResizeGrip.Margin = new Thickness(PanelResizeGeometry.GripInset, 0, 0, PanelResizeGeometry.GripInset);
                ResizeGrip.RenderTransform = new ScaleTransform(-1, 1);
                break;
        }
    }

    void Remember(MonitorDescriptor monitor, DipRect frame) =>
        WindowPlacement.Apply(this, frame, monitor.Dpi);

    void PersistPlacement(IReadOnlyList<MonitorDescriptor> monitors)
    {
        var settings = _session.Settings;
        var id = settings.ResolvedMonitorId();
        var edge = settings.ResolvedPlacementEdge();
        var monitor = SelectMonitor(monitors);
        var foundSaved = false;
        if (!string.IsNullOrWhiteSpace(id))
        {
            foreach (var candidate in monitors)
            {
                if (string.Equals(candidate.DeviceName, id, StringComparison.OrdinalIgnoreCase))
                {
                    monitor = candidate;
                    foundSaved = true;
                    break;
                }
            }
        }

        if (!foundSaved)
        {
            monitor = MonitorMigration.Primary(monitors);
        }

        double? offset = settings.Placement?.Offset ?? settings.EdgeOffset;
        double? clamped = offset;
        if (offset is double value)
        {
            var next = EdgeGeometry.ClampOffset(value, edge, monitor.WorkingArea, WedgeLength);
            if (Math.Abs(next - value) > 0.01)
            {
                clamped = next;
            }
        }

        var monitorChanged = !string.Equals(monitor.DeviceName, id, StringComparison.OrdinalIgnoreCase);
        var storedTop = string.Equals(settings.Placement?.Edge, nameof(ScreenEdge.Top), StringComparison.OrdinalIgnoreCase)
            || (string.IsNullOrWhiteSpace(settings.Placement?.Edge) && string.Equals(settings.Edge, nameof(ScreenEdge.Top), StringComparison.OrdinalIgnoreCase));
        var edgeChanged = !string.Equals(settings.Edge, edge.ToString(), StringComparison.OrdinalIgnoreCase)
            || (settings.Placement?.Edge is string nested && !string.Equals(nested, edge.ToString(), StringComparison.OrdinalIgnoreCase));
        if (!monitorChanged && !storedTop && !edgeChanged && Nullable.Equals(clamped, offset) && !string.IsNullOrWhiteSpace(id))
        {
            return;
        }

        settings.MonitorDeviceName = monitor.DeviceName;
        settings.Edge = edge.ToString();
        settings.EdgeOffset = clamped;
        settings.Placement = new PlacementSettings
        {
            Monitor = monitor.DeviceName,
            Edge = edge.ToString(),
            Offset = clamped
        };
        _store.Save(settings);
    }

    MonitorDescriptor SelectMonitor(IReadOnlyList<MonitorDescriptor> monitors)
    {
        var id = _session.Settings.ResolvedMonitorId();
        if (!string.IsNullOrWhiteSpace(id))
        {
            foreach (var monitor in monitors)
            {
                if (string.Equals(monitor.DeviceName, id, StringComparison.OrdinalIgnoreCase))
                {
                    return monitor;
                }
            }
        }

        return MonitorMigration.Primary(monitors);
    }

    IReadOnlyList<MonitorDescriptor> MonitorsOrWindow()
    {
        var monitors = NativeMonitor.All();
        if (monitors.Count > 0)
        {
            return monitors;
        }

        var fromWindow = NativeMonitor.FromWindow(new System.Windows.Interop.WindowInteropHelper(this).Handle);
        return fromWindow is MonitorDescriptor one ? [one] : monitors;
    }

    void UpdateCursor(DipPoint dip, bool expanded)
    {
        if (!expanded)
        {
            Cursor = Cursors.SizeAll;
            return;
        }

        Cursor = PanelResizeGeometry.BeginsResize(dip.X, dip.Y, _layout.ContentFrame, _layout.Anchor.Edge)
            ? ResizeCursor(_layout.Anchor.Edge)
            : DragHandleGeometry.Rect(_layout, expanded: true, WedgeLength, LayoutMetrics.HitThickness).ContainsPoint(dip.X, dip.Y)
                ? Cursors.SizeAll
                : Cursors.Arrow;
    }

    static Cursor ResizeCursor(ScreenEdge edge) => edge switch
    {
        ScreenEdge.Left => Cursors.SizeNWSE,
        ScreenEdge.Bottom => Cursors.SizeNESW,
        _ => Cursors.SizeNESW
    };

    static DipPoint DipOnMonitor(MonitorDescriptor monitor, int x, int y) =>
        new(monitor.Scale.ToDip(x), monitor.Scale.ToDip(y));

    double WedgeLength => _session.Settings.WedgeLength > 0
        ? _session.Settings.WedgeLength
        : LayoutMetrics.WedgeLength;

    bool IsVisuallyExpanded =>
        !_dragging && _session.Hover.Phase is HoverPhase.Expanded or HoverPhase.Pinned;

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
        var wedge = light ? Color.FromRgb(72, 128, 176) : Color.FromRgb(142, 184, 220);
        var grip = light ? Color.FromArgb(140, 60, 60, 67) : Color.FromArgb(160, 230, 230, 235);
        var opacity = Math.Clamp(settings.PanelOpacity, 0.70, 1);
        ExpandedChrome.Background = new SolidColorBrush(Color.FromArgb((byte)Math.Round(255 * opacity), card.R, card.G, card.B));
        ExpandedChrome.BorderBrush = new SolidColorBrush(line);
        TitleText.Foreground = new SolidColorBrush(ink);
        SubtitleText.Foreground = new SolidColorBrush(ink);
        var wedgeBrush = new SolidColorBrush(wedge);
        CollapsedChrome.Background = wedgeBrush;
        DragHandleMark.Background = wedgeBrush;
        CollapsedChrome.Opacity = Math.Clamp(settings.WedgeOpacity, 0.2, 1);
        DragHandleMark.Opacity = CollapsedChrome.Opacity;
        var gripBrush = new SolidColorBrush(grip);
        GripTickA.Background = gripBrush;
        GripTickB.Background = gripBrush;
        GripTickC.Background = gripBrush;
    }
}
