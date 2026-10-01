using PeekMemo.Core.Layout;
using PeekMemo.Core.Models;

namespace PeekMemo.Core.Geometry;

/// Collapsed: the wedge is the drag target. Expanded: a wedge-sized handle on the outer edge.
/// The handle is not the panel.
public static class DragHandleGeometry
{
    public static DipRect Rect(
        PlacementLayout layout,
        bool expanded,
        double stackLength = LayoutMetrics.WedgeLength,
        double hitThickness = LayoutMetrics.HitThickness)
    {
        if (!expanded)
        {
            return layout.CollapsedFrame;
        }

        var edge = layout.Anchor.Edge;
        if (edge == ScreenEdge.Bottom)
        {
            var length = Math.Min(Math.Max(0, stackLength), Math.Max(0, layout.ExpandedFrame.Width));
            var minX = layout.ExpandedFrame.X;
            var maxX = layout.ExpandedFrame.Right - length;
            var x = layout.HandleAttachmentPoint.X - length / 2;
            x = maxX < minX ? minX : Math.Clamp(x, minX, maxX);
            return new DipRect(x, layout.ExpandedFrame.Bottom - hitThickness, length, hitThickness);
        }

        var height = Math.Min(Math.Max(0, stackLength), Math.Max(0, layout.ExpandedFrame.Height));
        var minY = layout.ExpandedFrame.Y;
        var maxY = layout.ExpandedFrame.Bottom - height;
        var y = layout.HandleAttachmentPoint.Y - height / 2;
        y = maxY < minY ? minY : Math.Clamp(y, minY, maxY);
        var xEdge = edge == ScreenEdge.Left
            ? layout.ExpandedFrame.X
            : layout.ExpandedFrame.Right - hitThickness;
        return new DipRect(xEdge, y, hitThickness, height);
    }
}

/// Hover is the real collapsed wedge, or the expanded card plus the edge handle.
/// It is not the bounding union of those rectangles.
public readonly record struct HoverRegions(DipRect Primary, DipRect Secondary)
{
    public bool Contains(double x, double y) =>
        Primary.ContainsPoint(x, y) || Secondary.ContainsPoint(x, y);

    public static HoverRegions For(PlacementLayout layout, bool expanded)
    {
        var handle = DragHandleGeometry.Rect(layout, expanded);
        return expanded
            ? new HoverRegions(layout.ContentFrame, handle)
            : new HoverRegions(layout.CollapsedFrame, layout.CollapsedFrame);
    }
}
