using System.Runtime.InteropServices;
using PeekMemo.Core.Geometry;

namespace PeekMemo.Windows.Windowing;

internal readonly record struct ScreenWorkArea(string DeviceName, DipRect Bounds);

internal static class NativeMonitor
{
    const uint DefaultToPrimary = 1;
    const int EffectiveDpi = 0;

    public static ScreenWorkArea? Primary()
    {
        var monitor = MonitorFromPoint(new PointNative(), DefaultToPrimary);
        return Read(monitor);
    }

    public static ScreenWorkArea? Read(IntPtr monitor)
    {
        if (monitor == IntPtr.Zero)
        {
            return null;
        }

        var info = new MonitorInfoEx { cbSize = Marshal.SizeOf<MonitorInfoEx>() };
        if (!GetMonitorInfo(monitor, ref info))
        {
            return null;
        }

        var dpi = 96u;
        if (GetDpiForMonitor(monitor, EffectiveDpi, out var dpiX, out _) == 0 && dpiX > 0)
        {
            dpi = dpiX;
        }

        var bounds = MonitorScale.ToDip(info.rcWork.Left, info.rcWork.Top, info.rcWork.Right, info.rcWork.Bottom, dpi);
        return new ScreenWorkArea(info.szDevice ?? "", bounds);
    }

    [DllImport("user32.dll")]
    static extern IntPtr MonitorFromPoint(PointNative pt, uint flags);

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
        public int cbSize;
        public RectNative rcMonitor;
        public RectNative rcWork;
        public uint dwFlags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string szDevice;
    }
}
