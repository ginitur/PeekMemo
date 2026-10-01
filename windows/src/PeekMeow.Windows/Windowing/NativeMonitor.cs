using System.Collections.Generic;
using System.Runtime.InteropServices;
using PeekMeow.Core.Geometry;

namespace PeekMeow.Windows.Windowing;

internal static class NativeMonitor
{
    const uint DefaultToNearest = 2;
    const int EffectiveDpi = 0;
    const uint PrimaryFlag = 1;

    public static IReadOnlyList<MonitorDescriptor> All()
    {
        var found = new List<MonitorDescriptor>();
        MonitorEnumProc callback = (IntPtr monitor, IntPtr _, IntPtr _, IntPtr _) =>
        {
            if (TryRead(monitor, out var descriptor))
            {
                found.Add(descriptor);
            }

            return true;
        };
        EnumDisplayMonitors(IntPtr.Zero, IntPtr.Zero, callback, IntPtr.Zero);
        GC.KeepAlive(callback);
        return found;
    }

    public static MonitorDescriptor? FromPoint(int x, int y) =>
        Read(MonitorFromPoint(new PointNative { X = x, Y = y }, DefaultToNearest));

    public static MonitorDescriptor? FromWindow(IntPtr hwnd)
    {
        if (hwnd == IntPtr.Zero)
        {
            return null;
        }

        return Read(MonitorFromWindow(hwnd, DefaultToNearest));
    }

    public static bool TryCursor(out int x, out int y)
    {
        if (!GetCursorPos(out var point))
        {
            x = 0;
            y = 0;
            return false;
        }

        x = point.X;
        y = point.Y;
        return true;
    }

    public static uint WindowDpi(IntPtr hwnd)
    {
        if (hwnd == IntPtr.Zero)
        {
            return 0;
        }

        return GetDpiForWindow(hwnd);
    }

    static MonitorDescriptor? Read(IntPtr monitor) =>
        TryRead(monitor, out var descriptor) ? descriptor : null;

    static bool TryRead(IntPtr monitor, out MonitorDescriptor descriptor)
    {
        descriptor = default;
        if (monitor == IntPtr.Zero)
        {
            return false;
        }

        var info = new MonitorInfoEx { Size = Marshal.SizeOf<MonitorInfoEx>() };
        if (!GetMonitorInfo(monitor, ref info))
        {
            return false;
        }

        var dpi = 96u;
        if (GetDpiForMonitor(monitor, EffectiveDpi, out var dpiX, out _) == 0 && dpiX > 0)
        {
            dpi = dpiX;
        }

        var name = (info.Device ?? "").TrimEnd('\0').Trim();
        descriptor = new MonitorDescriptor(
            name,
            new PixelRect(info.Monitor.Left, info.Monitor.Top, info.Monitor.Right, info.Monitor.Bottom),
            new PixelRect(info.Work.Left, info.Work.Top, info.Work.Right, info.Work.Bottom),
            dpi,
            (info.Flags & PrimaryFlag) != 0);
        return true;
    }

    delegate bool MonitorEnumProc(IntPtr hMonitor, IntPtr hdcMonitor, IntPtr lprcMonitor, IntPtr dwData);

    [DllImport("user32.dll")]
    static extern bool EnumDisplayMonitors(IntPtr hdc, IntPtr lprcClip, MonitorEnumProc lpfnEnum, IntPtr dwData);

    [DllImport("user32.dll")]
    static extern IntPtr MonitorFromPoint(PointNative pt, uint flags);

    [DllImport("user32.dll")]
    static extern IntPtr MonitorFromWindow(IntPtr hwnd, uint flags);

    [DllImport("user32.dll")]
    static extern bool GetCursorPos(out PointNative point);

    [DllImport("user32.dll")]
    static extern uint GetDpiForWindow(IntPtr hwnd);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    static extern bool GetMonitorInfo(IntPtr hMonitor, ref MonitorInfoEx info);

    [DllImport("shcore.dll")]
    static extern int GetDpiForMonitor(IntPtr hmonitor, int dpiType, out uint dpiX, out uint dpiY);

    [StructLayout(LayoutKind.Sequential)]
    struct PointNative
    {
        public int X;
        public int Y;
    }

    [StructLayout(LayoutKind.Sequential)]
    struct RectNative
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    struct MonitorInfoEx
    {
        public int Size;
        public RectNative Monitor;
        public RectNative Work;
        public uint Flags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string Device;
    }
}
