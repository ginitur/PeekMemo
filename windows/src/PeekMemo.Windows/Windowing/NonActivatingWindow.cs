using System.Windows;
using System.Windows.Interop;

namespace PeekMemo.Windows.Windowing;

public class NonActivatingWindow : Window
{
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

    protected override void OnSourceInitialized(EventArgs e)
    {
        base.OnSourceInitialized(e);
        var hwnd = new WindowInteropHelper(this).Handle;
        WindowStyles.MakeNoActivateToolWindow(hwnd);
        WindowStyles.KeepTopmostWithoutActivating(hwnd);
    }
}
