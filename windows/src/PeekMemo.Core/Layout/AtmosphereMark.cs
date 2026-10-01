namespace PeekMemo.Core.Layout;

/// Faint corner artwork. It never takes layout space and never sits above the tasks.
public static class AtmosphereMark
{
    public const double MinimumWidthFraction = 0.22;
    public const double MaximumWidthFraction = 0.32;
    public const double DarkOpacity = 0.20;
    public const double LightOpacity = 0.12;
    public const double BleedFraction = 0.14;

    public readonly record struct Layout(double Width, double Opacity, double Bleed);

    public static Layout Place(double panelWidth, double panelHeight, bool lightBackground)
    {
        var width = Math.Max(panelWidth, 0);
        var height = Math.Max(panelHeight, 0);
        if (width < 1 || height < 1)
        {
            return new Layout(0, 0, 0);
        }

        double fraction;
        if (width < 280)
        {
            fraction = MinimumWidthFraction * (width / 280);
        }
        else
        {
            var t = Math.Clamp((width - 280) / 180, 0, 1);
            fraction = 0.24 + (MaximumWidthFraction - 0.24) * t;
        }

        var fitted = fraction;
        if (height < 460)
        {
            fitted *= Math.Max(0.35, height / 460);
        }

        fitted = Math.Min(fitted, MaximumWidthFraction);
        var opacity = lightBackground ? LightOpacity : DarkOpacity;
        if (height < 340)
        {
            opacity *= Math.Max(0.15, height / 340);
        }

        if (width < 260)
        {
            opacity *= Math.Max(0.25, width / 260);
        }

        if (height < 220 || width < 200)
        {
            opacity *= 0.35;
        }

        opacity = Math.Clamp(opacity, 0, DarkOpacity);
        var markWidth = width * fitted;
        return new Layout(markWidth, opacity, markWidth * BleedFraction);
    }
}
