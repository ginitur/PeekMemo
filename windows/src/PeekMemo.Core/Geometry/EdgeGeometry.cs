using PeekMemo.Core.Layout;
using PeekMemo.Core.Models;

namespace PeekMemo.Core.Geometry;

public static class EdgeGeometry
{
    public static double Span(ScreenEdge edge, DipRect workingArea) =>
        PlacementPolicy.SupportedOrRight(edge) is ScreenEdge.Left or ScreenEdge.Right
            ? workingArea.Height
            : workingArea.Width;

    /// Keeps the wedge center inside the working area. A span shorter than the wedge uses the midpoint.
    public static double ClampOffset(double offset, ScreenEdge edge, DipRect workingArea, double stackLength)
    {
        edge = PlacementPolicy.SupportedOrRight(edge);
        var span = Math.Max(0, Span(edge, workingArea));
        if (!double.IsFinite(offset))
        {
            return span / 2;
        }

        var half = Math.Max(0, stackLength) / 2;
        var min = Math.Min(half, span / 2);
        var max = Math.Max(span - half, min);
        return Math.Clamp(offset, min, max);
    }

    public static DipPoint AnchorPoint(ScreenEdge edge, DipRect workingArea, double offset)
    {
        edge = PlacementPolicy.SupportedOrRight(edge);
        return edge switch
        {
            ScreenEdge.Left => new DipPoint(workingArea.X, workingArea.Y + offset),
            ScreenEdge.Bottom => new DipPoint(workingArea.X + offset, workingArea.Bottom),
            _ => new DipPoint(workingArea.Right, workingArea.Y + offset)
        };
    }
}
