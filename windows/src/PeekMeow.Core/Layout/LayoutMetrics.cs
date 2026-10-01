namespace PeekMeow.Core.Layout;

public static class LayoutMetrics
{
    public const double VisibleWedgeThickness = 3;
    public const double HitThickness = 14;
    public const double WedgeLength = 56;
    public const double HoverOpenDelaySeconds = 0.16;
    public const double HoverCloseDelaySeconds = 0.35;
    public const double DragThreshold = 6;
    public const double SnapThreshold = 24;
    public const double SubtaskIndent = 18;
    public const double PanelOpacity = 0.94;
    public const double WedgeOpacity = 0.55;
}

public static class PanelSize
{
    public const double MinimumWidth = 280;
    public const double MinimumHeight = 300;
    public const double DefaultWidth = 340;
    public const double DefaultHeight = 460;
    public const double CornerRadius = 16;
    public const double BorderThickness = 1;
    public const double AbsoluteMaximum = 2400;

    public static (double Width, double Height) ClampStored(double width, double height) =>
        (Math.Clamp(width, MinimumWidth, AbsoluteMaximum), Math.Clamp(height, MinimumHeight, AbsoluteMaximum));
}
