using PeekMemo.Core.Models;

namespace PeekMemo.Core.Geometry;

public enum ResizeGripCorner
{
    BottomLeft,
    BottomRight,
    TopRight
}

/// The resize target is a corner square. It is not the panel.
public static class PanelResizeGeometry
{
    public const double GripSize = 22;
    public const double MaximumHitSize = 24;
    public const double VisualGripSize = 14;
    public const double GripInset = 6;

    public static ResizeGripCorner CornerFor(ScreenEdge edge) => edge switch
    {
        ScreenEdge.Right => ResizeGripCorner.BottomLeft,
        ScreenEdge.Left => ResizeGripCorner.BottomRight,
        ScreenEdge.Bottom => ResizeGripCorner.TopRight,
        _ => ResizeGripCorner.BottomRight
    };

    /// `content` uses the WPF origin: top-left, Y down.
    public static DipRect GripFrame(DipRect content, ScreenEdge edge)
    {
        var size = Math.Min(GripSize, MaximumHitSize);
        size = Math.Min(size, Math.Max(0, content.Width));
        size = Math.Min(size, Math.Max(0, content.Height));
        var inset = GripInset;
        return CornerFor(edge) switch
        {
            ResizeGripCorner.BottomLeft => new DipRect(
                content.X + inset,
                content.Bottom - inset - size,
                size,
                size),
            ResizeGripCorner.BottomRight => new DipRect(
                content.Right - inset - size,
                content.Bottom - inset - size,
                size,
                size),
            _ => new DipRect(
                content.Right - inset - size,
                content.Y + inset,
                size,
                size)
        };
    }

    public static bool BeginsResize(double x, double y, DipRect content, ScreenEdge edge) =>
        GripFrame(content, edge).ContainsPoint(x, y);
}
