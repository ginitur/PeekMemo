using PeekMemo.Core.Layout;
using PeekMemo.Core.Models;

namespace PeekMemo.Core.Geometry;

public readonly record struct DragSample(
    ScreenEdge Edge,
    double Offset,
    double Distance,
    DipRect Frame,
    bool Snapped);

/// Live drag follows the pointer. It magnet-snaps only inside <see cref="LayoutMetrics.SnapThreshold"/>.
/// Mouse-up always commits to the nearest of Left, Right, and Bottom. Top is not a candidate.
public static class DragGeometry
{
    public static (ScreenEdge Edge, double Distance) Nearest(double x, double y, DipRect workingArea)
    {
        (ScreenEdge Edge, double Distance) best = (ScreenEdge.Right, Math.Abs(x - workingArea.Right));
        Consider(ScreenEdge.Left, Math.Abs(x - workingArea.X));
        Consider(ScreenEdge.Bottom, Math.Abs(y - workingArea.Bottom));
        return best;

        void Consider(ScreenEdge edge, double distance)
        {
            if (distance < best.Distance)
            {
                best = (edge, distance);
            }
        }
    }

    public static double OffsetAlong(ScreenEdge edge, double x, double y, DipRect workingArea, double stackLength)
    {
        edge = PlacementPolicy.SupportedOrRight(edge);
        var raw = edge == ScreenEdge.Bottom ? x - workingArea.X : y - workingArea.Y;
        return EdgeGeometry.ClampOffset(raw, edge, workingArea, stackLength);
    }

    public static DragSample Live(
        double x,
        double y,
        DipRect workingArea,
        double stackLength = LayoutMetrics.WedgeLength,
        double hitThickness = LayoutMetrics.HitThickness,
        double magnet = LayoutMetrics.SnapThreshold)
    {
        var (edge, distance) = Nearest(x, y, workingArea);
        var offset = OffsetAlong(edge, x, y, workingArea, stackLength);
        if (distance <= magnet)
        {
            return new DragSample(
                edge,
                offset,
                distance,
                EdgePlacement.CollapsedHitRect(workingArea, edge, offset, hitThickness, stackLength),
                Snapped: true);
        }

        var frame = edge == ScreenEdge.Bottom
            ? new DipRect(x - stackLength / 2, y - hitThickness / 2, stackLength, hitThickness)
            : new DipRect(x - hitThickness / 2, y - stackLength / 2, hitThickness, stackLength);
        return new DragSample(edge, offset, distance, frame, Snapped: false);
    }

    public static DragSample Commit(
        double x,
        double y,
        DipRect workingArea,
        double stackLength = LayoutMetrics.WedgeLength,
        double hitThickness = LayoutMetrics.HitThickness)
    {
        var (edge, distance) = Nearest(x, y, workingArea);
        var offset = OffsetAlong(edge, x, y, workingArea, stackLength);
        return new DragSample(
            edge,
            offset,
            distance,
            EdgePlacement.CollapsedHitRect(workingArea, edge, offset, hitThickness, stackLength),
            Snapped: true);
    }
}

public static class PointerGesture
{
    public static bool PastDragThreshold(double dx, double dy)
    {
        var limit = LayoutMetrics.DragThreshold;
        return dx * dx + dy * dy >= limit * limit;
    }
}
