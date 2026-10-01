using System.Runtime.InteropServices;

namespace PeekMemo.Windows.Windowing;

internal static class WindowStyles
{
    const int GwlExStyle = -20;
    const long WsExToolWindow = 0x00000080;
    const long WsExNoActivate = 0x08000000;
    const uint SwpNoSize = 0x0001;
    const uint SwpNoMove = 0x0002;
    const uint SwpNoActivate = 0x0010;
    const uint SwpShowWindow = 0x0040;
    static readonly IntPtr HwndTopmost = new(-1);

    public static void MakeNoActivateToolWindow(IntPtr hwnd) => UsePeekMode(hwnd, peek: true);

    /// Peek keeps WS_EX_NOACTIVATE. Interactive mode, reserved for a later explicit edit, clears it.
    public static void UsePeekMode(IntPtr hwnd, bool peek)
    {
        var style = GetExStyle(hwnd).ToInt64();
        style |= WsExToolWindow;
        style = peek ? style | WsExNoActivate : style & ~WsExNoActivate;
        SetExStyle(hwnd, new IntPtr(style));
    }

    public static void KeepTopmostWithoutActivating(IntPtr hwnd)
    {
        SetWindowPos(hwnd, HwndTopmost, 0, 0, 0, 0, SwpNoMove | SwpNoSize | SwpNoActivate | SwpShowWindow);
    }

    public static void PlaceWithoutActivating(IntPtr hwnd, int x, int y, int width, int height)
    {
        SetWindowPos(hwnd, HwndTopmost, x, y, Math.Max(1, width), Math.Max(1, height), SwpNoActivate | SwpShowWindow);
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
}
