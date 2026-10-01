using PeekMeow.Core.Layout;
using PeekMeow.Core.Models;

namespace PeekMeow.Core.Geometry;

/// Resize translation is in DIPs. Positive X is right and positive Y is down.
/// The stored size is the user's request. The on-screen size may be smaller when the
/// working area cannot hold it, and that shrink is not written back.
public static class ResizeGeometry
{
    public static (double Width, double Height) Requested(
        double startWidth,
        double startHeight,
        double dx,
        double dy,
        ScreenEdge edge)
    {
        edge = PlacementPolicy.SupportedOrRight(edge);
        return edge switch
        {
            ScreenEdge.Right => (startWidth - dx, startHeight + dy),
            ScreenEdge.Left => (startWidth + dx, startHeight + dy),
            _ => (startWidth + dx, startHeight - dy)
        };
    }

    public static (double Width, double Height) ForDisplay(
        double width,
        double height,
        ScreenEdge edge,
        DipRect workingArea)
    {
        edge = PlacementPolicy.SupportedOrRight(edge);
        var vertical = edge is ScreenEdge.Left or ScreenEdge.Right;
        var maxWidth = Math.Max(0, vertical ? workingArea.Width - LayoutMetrics.HitThickness : workingArea.Width);
        var maxHeight = Math.Max(0, vertical ? workingArea.Height : workingArea.Height - LayoutMetrics.HitThickness);
        var lowerWidth = Math.Min(PanelSize.MinimumWidth, maxWidth);
        var lowerHeight = Math.Min(PanelSize.MinimumHeight, maxHeight);
        return (
            Math.Min(Math.Max(width, lowerWidth), Math.Max(lowerWidth, maxWidth)),
            Math.Min(Math.Max(height, lowerHeight), Math.Max(lowerHeight, maxHeight)));
    }

    public static (double Width, double Height) ForStore(double width, double height) =>
        PanelSize.ClampStored(width, height);
}
