using System.Drawing;
using System.IO;
using Forms = System.Windows.Forms;

namespace PeekMeow.Windows.Services;

internal sealed class TrayIcon : IDisposable
{
    readonly Forms.NotifyIcon _icon;
    readonly Icon? _ownedIcon;

    public TrayIcon(Action show, Action resetPosition, Action openSettings, Action quit)
    {
        var menu = new Forms.ContextMenuStrip();
        menu.Items.Add("Show PeekMeow", null, (_, _) => show());
        menu.Items.Add("Reset Position", null, (_, _) => resetPosition());
        menu.Items.Add("Settings", null, (_, _) => openSettings());
        menu.Items.Add("About PeekMeow", null, (_, _) => ShowAbout());
        menu.Items.Add("Quit PeekMeow", null, (_, _) => quit());

        _ownedIcon = LoadLogo();
        _icon = new Forms.NotifyIcon
        {
            Icon = _ownedIcon ?? System.Drawing.SystemIcons.Application,
            Visible = true,
            Text = "PeekMeow",
            ContextMenuStrip = menu
        };
        _icon.DoubleClick += (_, _) => show();
    }

    static void ShowAbout()
    {
        Forms.MessageBox.Show(
            "Version " + BuildIdentity.Version + "\nBuild " + BuildIdentity.Build + "\n\n" + (Environment.ProcessPath ?? ""),
            "About PeekMeow",
            Forms.MessageBoxButtons.OK,
            Forms.MessageBoxIcon.Information);
    }

    public void Dispose()
    {
        _icon.Visible = false;
        _icon.Dispose();
        _ownedIcon?.Dispose();
    }

    static Icon? LoadLogo()
    {
        var path = Path.Combine(AppContext.BaseDirectory, "PeekMeow.ico");
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
