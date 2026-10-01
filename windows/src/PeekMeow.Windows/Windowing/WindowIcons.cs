using System;
using System.IO;
using System.Windows.Media.Imaging;

namespace PeekMeow.Windows.Windowing;

static class WindowIcons
{
    public static BitmapFrame? Load()
    {
        var path = Path.Combine(AppContext.BaseDirectory, "PeekMeow.ico");
        if (!File.Exists(path))
        {
            return null;
        }

        try
        {
            return BitmapFrame.Create(new Uri(path), BitmapCreateOptions.None, BitmapCacheOption.OnLoad);
        }
        catch (IOException)
        {
            return null;
        }
        catch (NotSupportedException)
        {
            return null;
        }
    }
}
