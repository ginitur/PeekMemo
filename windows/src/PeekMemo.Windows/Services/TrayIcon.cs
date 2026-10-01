using Forms = System.Windows.Forms;

namespace PeekMemo.Windows.Services;

internal sealed class TrayIcon : IDisposable
{
    readonly Forms.NotifyIcon _icon;

    public TrayIcon(Action show, Action openSettings, Action quit)
    {
        var menu = new Forms.ContextMenuStrip();
        menu.Items.Add("Show PeekMemo", null, (_, _) => show());
        menu.Items.Add("Settings", null, (_, _) => openSettings());
        menu.Items.Add("Quit PeekMemo", null, (_, _) => quit());

        _icon = new Forms.NotifyIcon
        {
            Icon = System.Drawing.SystemIcons.Application,
            Visible = true,
            Text = "PeekMemo",
            ContextMenuStrip = menu
        };
        _icon.DoubleClick += (_, _) => show();
    }

    public void Dispose()
    {
        _icon.Visible = false;
        _icon.Dispose();
    }
}
