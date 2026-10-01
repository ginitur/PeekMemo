using PeekMemo.Core.Geometry;
using PeekMemo.Core.Layout;
using PeekMemo.Core.Models;
using Xunit;

namespace PeekMemo.Windows.Tests;

public class PlacementTests
{
    static readonly DipRect Work = new(0, 0, 1920, 1040);

    [Fact]
    public void RightCenterKeepsTheAnchorAsTheSourceOfTruth()
    {
        var anchor = new EdgeAnchor(@"\\.\DISPLAY1", ScreenEdge.Right, Work.Height / 2);
        var layout = PlacementLayout.Create(anchor, Work, PanelSize.DefaultWidth, PanelSize.DefaultHeight);

        Assert.Equal(anchor.Offset, layout.Anchor.Offset);
        Assert.Equal(Work.Right, layout.AnchorPoint.X);
        Assert.Equal(Work.Y + anchor.Offset, layout.AnchorPoint.Y);
        Assert.Equal(layout.AnchorPoint, layout.HandleAttachmentPoint);
        Assert.False(layout.WasClamped);
        Assert.Equal(Work.Right, layout.CollapsedFrame.Right);
        Assert.Equal(Work.Right, layout.ExpandedFrame.Right);
        Assert.Equal(PanelSize.DefaultWidth, layout.ContentFrame.Width);
        Assert.Equal(layout.AnchorPoint.Y, layout.ContentFrame.Y + layout.ContentFrame.Height / 2, 3);
    }

    [Fact]
    public void ExpandAndCollapseDoNotChangeTheOffset()
    {
        var anchor = new EdgeAnchor("m", ScreenEdge.Left, 400);
        var collapsed = PlacementLayout.Create(anchor, Work, 340, 460);
        var again = PlacementLayout.Create(collapsed.Anchor, Work, 340, 460);

        Assert.Equal(400d, collapsed.Anchor.Offset);
        Assert.Equal(400d, again.Anchor.Offset);
        Assert.Equal(ScreenEdge.Left, again.Anchor.Edge);
    }

    [Fact]
    public void HoverUsesTheCardAndTheHandleNotTheirBoundingUnion()
    {
        var card = new DipRect(14, 200, 340, 460);
        var handle = new DipRect(1906, 400, 14, 56);
        var regions = new HoverRegions(card, handle);

        Assert.True(regions.Contains(40, 240));
        Assert.True(regions.Contains(1910, 420));
        Assert.False(regions.Contains(900, 420));
        Assert.True(900 > Math.Min(card.X, handle.X));
        Assert.True(900 < Math.Max(card.Right, handle.Right));
    }

    [Fact]
    public void ExpandedHandleIsTheWedgeNotThePanel()
    {
        var layout = PlacementLayout.Create(
            new EdgeAnchor("m", ScreenEdge.Right, 520),
            Work,
            PanelSize.DefaultWidth,
            PanelSize.DefaultHeight);
        var handle = DragHandleGeometry.Rect(layout, expanded: true);

        Assert.Equal(LayoutMetrics.HitThickness, handle.Width);
        Assert.Equal(LayoutMetrics.WedgeLength, handle.Height);
        Assert.True(handle.Height < layout.ContentFrame.Height);
        Assert.False(handle.ContainsPoint(layout.ContentFrame.X + 20, layout.ContentFrame.Y + 20));
        Assert.False(HoverRegions.For(layout, expanded: true).Contains(layout.ExpandedFrame.Right - 2, layout.ExpandedFrame.Y + 2));
    }
}
