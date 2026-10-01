using System.Runtime.InteropServices;
using PeekMeow.Core.Interaction;

namespace PeekMeow.Windows.Windowing;

/// Switches peek and interactive without moving the locked frame.
/// Interactive is not a pin. Leaving it restores WS_EX_NOACTIVATE.
internal sealed class InteractionModeController
{
    PresentationMode _mode = PresentationMode.Peek;
    IntPtr _restoreForeground;

    public void Apply(IntPtr hwnd, PresentationMode mode)
    {
        if (hwnd == IntPtr.Zero || mode == _mode)
        {
            return;
        }

        if (mode == PresentationMode.Interactive)
        {
            var foreground = GetForegroundWindow();
            _restoreForeground = foreground == hwnd ? IntPtr.Zero : foreground;
            WindowStyles.UsePeekMode(hwnd, peek: false);
            _mode = PresentationMode.Interactive;
            SetForegroundWindow(hwnd);
            return;
        }

        WindowStyles.UsePeekMode(hwnd, peek: true);
        _mode = PresentationMode.Peek;
        var previous = _restoreForeground;
        _restoreForeground = IntPtr.Zero;
        if (previous != IntPtr.Zero && previous != hwnd)
        {
            SetForegroundWindow(previous);
        }
    }

    [DllImport("user32.dll")]
    static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    static extern bool SetForegroundWindow(IntPtr hWnd);
}
