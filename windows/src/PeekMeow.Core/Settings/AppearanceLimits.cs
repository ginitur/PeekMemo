namespace PeekMeow.Core.Settings;

public enum PanelBackgroundMode
{
    Default,
    Solid,
    Image
}

public enum BackgroundFit
{
    Fill,
    Fit
}

public enum BackgroundAnchor
{
    Top,
    Center,
    Bottom
}

/// Fill crops. Fit letterboxes. Neither mode stretches the picture.
public enum BackgroundStretch
{
    Uniform,
    UniformToFill
}

public static class AppearanceLimits
{
    public static double PanelOpacity(double value) => Math.Clamp(value, 0.70, 1);
    public static double SolidOpacity(double value) => Math.Clamp(value, 0.40, 1);
    public static double ImageOpacity(double value) => Math.Clamp(value, 0.20, 1);
    public static double OverlayOpacity(double value) => Math.Clamp(value, 0, 0.80);
    public static double WedgeThickness(double value) => Math.Clamp(value, 2, 6);
    public static double WedgeLength(double value) => Math.Clamp(value, 32, 96);
    public static double WedgeOpacity(double value) => Math.Clamp(value, 0.20, 1);
}

public static class BackgroundLayout
{
    public static BackgroundStretch StretchFor(BackgroundFit fit) =>
        fit == BackgroundFit.Fit ? BackgroundStretch.Uniform : BackgroundStretch.UniformToFill;
}

public static class StoredColor
{
    public static string? Normalize(string? text)
    {
        if (string.IsNullOrWhiteSpace(text))
        {
            return null;
        }

        var raw = text.Trim();
        if (raw.StartsWith('#'))
        {
            raw = raw[1..];
        }

        if (raw.Length is not (6 or 8) || !raw.All(Uri.IsHexDigit))
        {
            return null;
        }

        return "#" + raw.ToUpperInvariant();
    }
}
