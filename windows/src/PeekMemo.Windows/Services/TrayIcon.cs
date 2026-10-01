using System.Drawing;
using System.IO;
using Forms = System.Windows.Forms;

namespace PeekMemo.Windows.Services;

internal sealed class TrayIcon : IDisposable
{
    readonly Forms.NotifyIcon _icon;
    readonly Icon? _ownedIcon;

    public TrayIcon(Action show, Action resetPosition, Action openSettings, Action quit)
    {
        var menu = new Forms.ContextMenuStrip();
        menu.Items.Add("Show PeekMemo", null, (_, _) => show());
        menu.Items.Add("Reset Position", null, (_, _) => resetPosition());
        menu.Items.Add("Settings", null, (_, _) => openSettings());
        menu.Items.Add("Quit PeekMemo", null, (_, _) => quit());

        _ownedIcon = LoadLogo();
        _icon = new Forms.NotifyIcon
        {
            Icon = _ownedIcon ?? System.Drawing.SystemIcons.Application,
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
        _ownedIcon?.Dispose();
    }

    static Icon? LoadLogo()
    {
        var path = Path.Combine(AppContext.BaseDirectory, "PeekMemo.ico");
        if (!File.Exists(path))
        {
            return null;
        }

        try
        {
            return new Icon(path, 16, 16);
        }
        catch (ArgumentException)
        {
            return null;
        }
    }
}
