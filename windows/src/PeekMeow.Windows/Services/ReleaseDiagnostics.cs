using System.Text;
using System.Windows;
using System.Windows.Media.Imaging;
using PeekMeow.Core.Daily;
using PeekMeow.Core.Settings;
using PeekMeow.Windows.Views;

namespace PeekMeow.Windows.Services;

internal static class ReleaseDiagnostics
{
    public static string Describe()
    {
        var root = AppPaths.DefaultRoot();
        var mark = TryDecodeMark(out var markDetail);
        var builder = new StringBuilder();
        builder.AppendLine("Version: " + BuildIdentity.Version);
        builder.AppendLine("Commit SHA: " + BuildIdentity.Commit);
        builder.AppendLine("Build: " + BuildIdentity.Build);
        builder.AppendLine("Executable Path: " + (Environment.ProcessPath ?? ""));
        builder.AppendLine("Process ID: " + Environment.ProcessId);
        builder.AppendLine("Database Path: " + AppPaths.DatabaseFile(root));
        builder.AppendLine("Settings Path: " + AppPaths.SettingsFile(root));
        builder.AppendLine("Resource presence:");
        builder.AppendLine("  PeekMeowMark = " + (mark ? "yes" : "no") + " (" + markDetail + ")");
        builder.Append("Quote feature = " + (QuotePresent() ? "yes" : "no"));
        return builder.ToString();
    }

    public static int RunSmokeUi()
    {
        var failures = new StringBuilder();
        if (string.IsNullOrWhiteSpace(BuildIdentity.Version) || BuildIdentity.Version == "unknown")
        {
            failures.AppendLine("version missing");
        }

        if (string.IsNullOrWhiteSpace(BuildIdentity.Commit) || BuildIdentity.Commit == "unknown")
        {
            failures.AppendLine("commit missing");
        }

        if (!QuotePresent())
        {
            failures.AppendLine("quote missing");
        }

        if (typeof(CategoryPopupWindow).FullName != "PeekMeow.Windows.Views.CategoryPopupWindow")
        {
            failures.AppendLine("CategoryPopupWindow missing");
        }

        if (!TryDecodeMark(out var markDetail))
        {
            failures.AppendLine("PeekMeowMark " + markDetail);
        }

        var report = Describe() + "\n" + (failures.Length == 0 ? "smoke-ui: ok" : "smoke-ui: failed\n" + failures);
        ConsoleAttach.Write(report.TrimEnd());
        return failures.Length == 0 ? 0 : 1;
    }

    public static bool QuotePresent()
    {
        return BrandQuote.Text.Contains('\u2019')
            && BrandQuote.Text.StartsWith("Toutes les grandes personnes", StringComparison.Ordinal);
    }

    public static bool TryDecodeMark(out string detail)
    {
        try
        {
            var info = Application.GetResourceStream(new Uri("pack://application:,,,/Assets/PeekMeowMark.png", UriKind.Absolute));
            if (info?.Stream is null)
            {
                detail = "pack uri returned no stream";
                return false;
            }

            using (info.Stream)
            {
                var decoder = new PngBitmapDecoder(info.Stream, BitmapCreateOptions.PreservePixelFormat, BitmapCacheOption.OnLoad);
                if (decoder.Frames.Count == 0 || decoder.Frames[0].PixelWidth < 1 || decoder.Frames[0].PixelHeight < 1)
                {
                    detail = "decoder returned no frame";
                    return false;
                }

                var frame = decoder.Frames[0];
                detail = frame.PixelWidth + "x" + frame.PixelHeight;
                return true;
            }
        }
        catch (Exception exception)
        {
            detail = exception.GetType().Name + ": " + exception.Message;
            return false;
        }
    }
}
