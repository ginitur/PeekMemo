using PeekMeow.Core.Layout;
using PeekMeow.Core.Models;

namespace PeekMeow.Core.Geometry;

/// Places the wedge and the expanded panel inside a monitor working area.
/// The working area already excludes the taskbar. Callers must not pass a hard-coded resolution.
public static class EdgePlacement
{
    public static double ResolveOffset(double? storedOffset, double span)
    {
        if (storedOffset is double offset)
        {
            return offset;
        }

        return span / 2;
    }

    public static DipRect CollapsedHitRect(
        DipRect workingArea,
        ScreenEdge edge,
        double anchorOffset,
        double hitThickness = LayoutMetrics.HitThickness,
        double length = LayoutMetrics.WedgeLength)
    {
        edge = PlacementPolicy.SupportedOrRight(edge);
        hitThickness = Math.Clamp(hitThickness, 0, edge is ScreenEdge.Left or ScreenEdge.Right
            ? Math.Max(0, workingArea.Width)
            : Math.Max(0, workingArea.Height));

        if (edge is ScreenEdge.Left or ScreenEdge.Right)
        {
            var clampedLength = Math.Min(Math.Max(0, length), Math.Max(0, workingArea.Height));
            var y = ClampCenter(workingArea.Y + anchorOffset, clampedLength, workingArea.Y, workingArea.Bottom);
            var x = edge == ScreenEdge.Left ? workingArea.X : workingArea.Right - hitThickness;
            return new DipRect(x, y, hitThickness, clampedLength);
        }

        var clampedWidth = Math.Min(Math.Max(0, length), Math.Max(0, workingArea.Width));
        var xBottom = ClampCenter(workingArea.X + anchorOffset, clampedWidth, workingArea.X, workingArea.Right);
        return new DipRect(xBottom, workingArea.Bottom - hitThickness, clampedWidth, hitThickness);
    }

    public static DipRect VisibleWedge(DipRect hitRect, ScreenEdge edge, double visibleThickness = LayoutMetrics.VisibleWedgeThickness)
    {
        edge = PlacementPolicy.SupportedOrRight(edge);
        if (edge is ScreenEdge.Left or ScreenEdge.Right)
        {
            var thickness = Math.Min(Math.Max(0, visibleThickness), hitRect.Width);
            var x = edge == ScreenEdge.Left ? hitRect.X : hitRect.Right - thickness;
            return new DipRect(x, hitRect.Y, thickness, hitRect.Height);
        }

        var height = Math.Min(Math.Max(0, visibleThickness), hitRect.Height);
        return new DipRect(hitRect.X, hitRect.Bottom - height, hitRect.Width, height);
    }

    public static DipRect ExpandedFrame(
        DipRect workingArea,
        ScreenEdge edge,
        double anchorOffset,
        double panelWidth = PanelSize.DefaultWidth,
        double panelHeight = PanelSize.DefaultHeight,
        double hitThickness = LayoutMetrics.HitThickness)
    {
        edge = PlacementPolicy.SupportedOrRight(edge);
        if (edge is ScreenEdge.Left or ScreenEdge.Right)
        {
            var width = Math.Min(Math.Max(0, panelWidth + hitThickness), Math.Max(0, workingArea.Width));
            var height = Math.Min(Math.Max(0, panelHeight), Math.Max(0, workingArea.Height));
            var y = ClampCenter(workingArea.Y + anchorOffset, height, workingArea.Y, workingArea.Bottom);
            var x = edge == ScreenEdge.Left ? workingArea.X : workingArea.Right - width;
            return new DipRect(x, y, width, height);
        }

        var bottomWidth = Math.Min(Math.Max(0, panelWidth), Math.Max(0, workingArea.Width));
        var bottomHeight = Math.Min(Math.Max(0, panelHeight + hitThickness), Math.Max(0, workingArea.Height));
        var xBottom = ClampCenter(workingArea.X + anchorOffset, bottomWidth, workingArea.X, workingArea.Right);
        return new DipRect(xBottom, workingArea.Bottom - bottomHeight, bottomWidth, bottomHeight);
    }

    static double ClampCenter(double center, double length, double min, double max)
    {
        var start = center - length / 2;
        var limit = max - length;
        if (limit < min)
        {
            return min;
        }

        return Math.Clamp(start, min, limit);
    }
}
