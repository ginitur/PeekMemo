using PeekMeow.Core.Layout;
using PeekMeow.Core.Models;

namespace PeekMeow.Core.Geometry;

/// Windows coordinates: origin top-left, X right, Y down, units DIP.
/// The anchor is the source of truth. Expand, collapse, hover, and resize do not change
/// <see cref="EdgeAnchor.Offset"/>. Near a corner the panel body moves; the handle stays
/// on the anchor.
/// Right keeps expanded max X on the working-area right and grows left.
/// Left keeps expanded min X on the working-area left and grows right.
/// Bottom keeps expanded max Y on the working-area bottom and grows up.
public readonly record struct PlacementLayout(
    EdgeAnchor Anchor,
    DipPoint AnchorPoint,
    DipRect CollapsedFrame,
    DipRect ExpandedFrame,
    DipRect ContentFrame,
    DipPoint HandleAttachmentPoint,
    double HandleOffsetInsidePanel,
    bool WasClamped)
{
    public static PlacementLayout Create(
        EdgeAnchor anchor,
        DipRect workingArea,
        double panelWidth,
        double panelHeight,
        double stackLength = LayoutMetrics.WedgeLength,
        double hitThickness = LayoutMetrics.HitThickness)
    {
        var edge = PlacementPolicy.SupportedOrRight(anchor.Edge);
        var stored = new EdgeAnchor(anchor.MonitorIdentifier ?? "", edge, anchor.Offset);
        var displayOffset = EdgeGeometry.ClampOffset(anchor.Offset, edge, workingArea, stackLength);
        var (width, height) = ResizeGeometry.ForDisplay(panelWidth, panelHeight, edge, workingArea);
        var anchorPoint = EdgeGeometry.AnchorPoint(edge, workingArea, displayOffset);
        var collapsed = EdgePlacement.CollapsedHitRect(workingArea, edge, displayOffset, hitThickness, stackLength);

        double contentX;
        double contentY;
        if (edge == ScreenEdge.Right)
        {
            contentX = workingArea.Right - hitThickness - width;
            contentY = anchorPoint.Y - height / 2;
        }
        else if (edge == ScreenEdge.Left)
        {
            contentX = workingArea.X + hitThickness;
            contentY = anchorPoint.Y - height / 2;
        }
        else
        {
            contentX = anchorPoint.X - width / 2;
            contentY = workingArea.Bottom - hitThickness - height;
        }

        var unclampedX = contentX;
        var unclampedY = contentY;
        if (edge is ScreenEdge.Left or ScreenEdge.Right)
        {
            var maxY = workingArea.Bottom - height;
            contentY = maxY < workingArea.Y ? workingArea.Y : Math.Clamp(contentY, workingArea.Y, maxY);
        }
        else
        {
            var maxX = workingArea.Right - width;
            contentX = maxX < workingArea.X ? workingArea.X : Math.Clamp(contentX, workingArea.X, maxX);
        }

        var content = new DipRect(contentX, contentY, width, height);
        var expanded = edge switch
        {
            ScreenEdge.Left => new DipRect(workingArea.X, content.Y, width + hitThickness, height),
            ScreenEdge.Bottom => new DipRect(content.X, content.Y, width, height + hitThickness),
            _ => new DipRect(content.X, content.Y, width + hitThickness, height)
        };

        var handleOffset = edge is ScreenEdge.Left or ScreenEdge.Right
            ? anchorPoint.Y - content.Y
            : anchorPoint.X - content.X;
        var wasClamped = Math.Abs(contentX - unclampedX) > 0.5 || Math.Abs(contentY - unclampedY) > 0.5;

        return new PlacementLayout(
            stored,
            anchorPoint,
            collapsed,
            expanded,
            content,
            anchorPoint,
            handleOffset,
            wasClamped);
    }
}
