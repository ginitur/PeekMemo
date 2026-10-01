using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Interop;
using PeekMemo.Core.Interaction;

namespace PeekMemo.Windows.Windowing;

public class NonActivatingWindow : Window
{
    const int WmWindowPosChanging = 0x0046;
    const int WmDisplayChange = 0x007E;
    const int WmDpiChanged = 0x02E0;
    const uint SwpNoSize = 0x0001;
    const uint SwpNoMove = 0x0002;

    readonly InteractionModeController _interactionMode = new();
    bool _hasLockedFrame;
    int _lockedX;
    int _lockedY;
    int _lockedWidth;
    int _lockedHeight;

    public NonActivatingWindow()
    {
        WindowStyle = WindowStyle.None;
        AllowsTransparency = true;
        Background = System.Windows.Media.Brushes.Transparent;
        ShowInTaskbar = false;
        Topmost = true;
        ShowActivated = false;
        ResizeMode = ResizeMode.NoResize;
        Focusable = false;
    }

    /// Physical pixels. WPF must not move this HWND from Left/Top: those are a different
    /// coordinate space once two monitors do not share a DPI.
    internal void LockPhysicalFrame(int x, int y, int width, int height)
    {
        _lockedX = x;
        _lockedY = y;
        _lockedWidth = Math.Max(1, width);
        _lockedHeight = Math.Max(1, height);
        _hasLockedFrame = true;
    }

    /// Hover and drag stay in peek mode. Editing and the date picker pass Interactive.
    public void SetPresentationMode(PresentationMode mode)
    {
        Focusable = mode == PresentationMode.Interactive;
        var hwnd = new WindowInteropHelper(this).Handle;
        _interactionMode.Apply(hwnd, mode);
    }

    protected virtual void OnDisplayMetricsChanged()
    {
    }

    protected override void OnSourceInitialized(EventArgs e)
    {
        base.OnSourceInitialized(e);
        var source = (HwndSource?)PresentationSource.FromVisual(this);
        var hwnd = source?.Handle ?? new WindowInteropHelper(this).Handle;
        WindowStyles.MakeNoActivateToolWindow(hwnd);
        WindowStyles.KeepTopmostWithoutActivating(hwnd);
        source?.AddHook(OnWindowMessage);
    }

    protected override void OnDpiChanged(DpiScale oldDpi, DpiScale newDpi)
    {
        base.OnDpiChanged(oldDpi, newDpi);
        Dispatcher.BeginInvoke(new Action(OnDisplayMetricsChanged));
    }

    IntPtr OnWindowMessage(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam, ref bool handled)
    {
        if (msg == WmWindowPosChanging && _hasLockedFrame)
        {
            ForceLockedFrame(lParam);
        }

        if (msg is WmDpiChanged or WmDisplayChange)
        {
            Dispatcher.BeginInvoke(new Action(OnDisplayMetricsChanged));
        }

        return IntPtr.Zero;
    }

    void ForceLockedFrame(IntPtr lParam)
    {
        var xOffset = IntPtr.Size * 2;
        Marshal.WriteInt32(lParam, xOffset, _lockedX);
        Marshal.WriteInt32(lParam, xOffset + 4, _lockedY);
        Marshal.WriteInt32(lParam, xOffset + 8, _lockedWidth);
        Marshal.WriteInt32(lParam, xOffset + 12, _lockedHeight);
        var flagsOffset = xOffset + 16;
        var flags = (uint)Marshal.ReadInt32(lParam, flagsOffset);
        flags &= ~(SwpNoMove | SwpNoSize);
        Marshal.WriteInt32(lParam, flagsOffset, unchecked((int)flags));
    }
}
