using System.Runtime.InteropServices;
using PeekMemo.Core.Interaction;

namespace PeekMemo.Windows.Windowing;

internal static class WindowStyles
{
    const int GwlExStyle = -20;
    const uint GwOwner = 4;
    const long ExTopmost = 0x00000008;
    const uint SwpShowWindow = 0x0040;
    static readonly IntPtr HwndTopmost = new(-1);
    static IntPtr _overlay;

    public static bool HasOverlay => _overlay != IntPtr.Zero;

    public static void TrackOverlay(IntPtr hwnd)
    {
        if (hwnd != IntPtr.Zero)
        {
            _overlay = hwnd;
        }
    }

    public static void ReleaseOverlay(IntPtr hwnd)
    {
        if (_overlay == hwnd)
        {
            _overlay = IntPtr.Zero;
        }
    }

    public static IntPtr OwnerOf(IntPtr hwnd)
    {
        if (hwnd == IntPtr.Zero)
        {
            return IntPtr.Zero;
        }

        return GetWindow(hwnd, GwOwner);
    }

    public static bool IsTopmost(IntPtr hwnd)
    {
        if (hwnd == IntPtr.Zero)
        {
            return false;
        }

        return (GetExStyle(hwnd).ToInt64() & ExTopmost) != 0;
    }

    public static void MakeNoActivateToolWindow(IntPtr hwnd) => UsePeekMode(hwnd, peek: true);

    /// Peek keeps WS_EX_NOACTIVATE. Interactive clears it. The position flags keep the frame still.
    public static void UsePeekMode(IntPtr hwnd, bool peek)
    {
        if (hwnd == IntPtr.Zero)
        {
            return;
        }

        var style = ActivationStyle.ForMode(GetExStyle(hwnd).ToInt64(), peek);
        SetExStyle(hwnd, new IntPtr(style));
        SetWindowPos(hwnd, IntPtr.Zero, 0, 0, 0, 0, ActivationStyle.FrameStable);
    }

    public static void KeepTopmostWithoutActivating(IntPtr hwnd)
    {
        if (PanelZOrder.PreserveOrder(HasOverlay) && hwnd != _overlay)
        {
            RaiseOverlay();
            return;
        }

        SetWindowPos(
            hwnd,
            HwndTopmost,
            0,
            0,
            0,
            0,
            ActivationStyle.NoMove | ActivationStyle.NoSize | ActivationStyle.NoActivatePosition | SwpShowWindow);
        if (hwnd != _overlay)
        {
            RaiseOverlay();
        }
    }

    public static void PlaceWithoutActivating(IntPtr hwnd, int x, int y, int width, int height)
    {
        var flags = ActivationStyle.NoActivatePosition | SwpShowWindow;
        var insertAfter = HwndTopmost;
        if (PanelZOrder.PreserveOrder(HasOverlay))
        {
            flags |= ActivationStyle.NoZOrder;
            insertAfter = IntPtr.Zero;
        }

        SetWindowPos(
            hwnd,
            insertAfter,
            x,
            y,
            Math.Max(1, width),
            Math.Max(1, height),
            flags);
        RaiseOverlay();
    }

    static void RaiseOverlay()
    {
        if (_overlay == IntPtr.Zero)
        {
            return;
        }

        SetWindowPos(
            _overlay,
            HwndTopmost,
            0,
            0,
            0,
            0,
            ActivationStyle.NoMove | ActivationStyle.NoSize | ActivationStyle.NoActivatePosition | SwpShowWindow);
    }

    static IntPtr GetExStyle(IntPtr hwnd) =>
        IntPtr.Size == 8 ? GetWindowLongPtr64(hwnd, GwlExStyle) : new IntPtr(GetWindowLong32(hwnd, GwlExStyle));

    static void SetExStyle(IntPtr hwnd, IntPtr style)
    {
        if (IntPtr.Size == 8)
        {
            SetWindowLongPtr64(hwnd, GwlExStyle, style);
            return;
        }

        SetWindowLong32(hwnd, GwlExStyle, style.ToInt32());
    }

    [DllImport("user32.dll", EntryPoint = "GetWindowLongW", CharSet = CharSet.Unicode)]
    static extern int GetWindowLong32(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll", EntryPoint = "SetWindowLongW", CharSet = CharSet.Unicode)]
    static extern int SetWindowLong32(IntPtr hWnd, int nIndex, int dwNewLong);

    [DllImport("user32.dll", EntryPoint = "GetWindowLongPtrW", CharSet = CharSet.Unicode)]
    static extern IntPtr GetWindowLongPtr64(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll", EntryPoint = "SetWindowLongPtrW", CharSet = CharSet.Unicode)]
    static extern IntPtr SetWindowLongPtr64(IntPtr hWnd, int nIndex, IntPtr dwNewLong);

    [DllImport("user32.dll", SetLastError = true)]
    static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int x, int y, int cx, int cy, uint flags);

    [DllImport("user32.dll")]
    static extern IntPtr GetWindow(IntPtr hWnd, uint uCmd);
}
