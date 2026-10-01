using System.Windows.Interop;
using PeekMeow.Core.Geometry;
using CoreDpi = PeekMeow.Core.Geometry.DpiScale;

namespace PeekMeow.Windows.Windowing;

/// Places a window from one monitor's DIP rect.
/// That space is physical pixels divided by this monitor's dpi/96, so it round-trips
/// through <see cref="CoreDpi.ToPixels"/>. It is not WPF's virtual-screen DIP: dividing
/// an absolute pixel by the window DPI jumps when the pointer crosses onto another scale.
/// The HWND rectangle stays in physical pixels. Width and Height stay in DIPs so a
/// 340 DIP panel is still 340 DIP at 125%, 150%, 175%, and 200%.
internal static class WindowPlacement
{
    public static void Apply(NonActivatingWindow window, DipRect frame, uint monitorDpi)
    {
        var width = Math.Max(1, frame.Width);
        var height = Math.Max(1, frame.Height);
        var hwnd = new WindowInteropHelper(window).Handle;
        if (hwnd == IntPtr.Zero)
        {
            window.Left = frame.X;
            window.Top = frame.Y;
            window.Width = width;
            window.Height = height;
            return;
        }

        var pixels = new CoreDpi(monitorDpi).ToPixels(new DipRect(frame.X, frame.Y, width, height));
        window.LockPhysicalFrame(pixels.Left, pixels.Top, pixels.Width, pixels.Height);
        WindowStyles.PlaceWithoutActivating(hwnd, pixels.Left, pixels.Top, pixels.Width, pixels.Height);
        window.Width = width;
        window.Height = height;
    }
}
