using PeekMemo.Core.Geometry;
using PeekMemo.Core.Layout;
using PeekMemo.Core.Models;
using Xunit;

namespace PeekMemo.Windows.Tests;

public class PanelExpandDirectionTests
{
    static readonly DipRect Work = new(40, 20, 1600, 900);

    [Fact]
    public void RightExpandsLeftAndKeepsMaxX()
    {
        var layout = Layout(ScreenEdge.Right, Work.Height / 2);

        Assert.Equal(Work.Right, layout.ExpandedFrame.Right);
        Assert.Equal(Work.Right, layout.CollapsedFrame.Right);
        Assert.True(layout.ContentFrame.X < layout.ExpandedFrame.Right - layout.ContentFrame.Width);
        Assert.Equal(LayoutMetrics.HitThickness, layout.ExpandedFrame.Right - layout.ContentFrame.Right);
        Assert.Equal(layout.Anchor.Offset, layout.HandleOffsetInsidePanel + (layout.ContentFrame.Y - Work.Y), 3);
    }

    [Fact]
    public void LeftExpandsRightAndKeepsMinX()
    {
        var layout = Layout(ScreenEdge.Left, Work.Height / 2);

        Assert.Equal(Work.X, layout.ExpandedFrame.X);
        Assert.Equal(Work.X, layout.CollapsedFrame.X);
        Assert.Equal(Work.X + LayoutMetrics.HitThickness, layout.ContentFrame.X);
        Assert.True(layout.ExpandedFrame.Right > layout.CollapsedFrame.Right);
    }

    [Fact]
    public void BottomExpandsUpAndKeepsMaxY()
    {
        var layout = Layout(ScreenEdge.Bottom, Work.Width / 2);

        Assert.Equal(Work.Bottom, layout.ExpandedFrame.Bottom);
        Assert.Equal(Work.Bottom, layout.CollapsedFrame.Bottom);
        Assert.Equal(Work.Bottom - LayoutMetrics.HitThickness, layout.ContentFrame.Bottom);
        Assert.True(layout.ContentFrame.Y < layout.CollapsedFrame.Y);
        Assert.Equal(layout.Anchor.Offset, layout.HandleOffsetInsidePanel + (layout.ContentFrame.X - Work.X), 3);
    }

    [Fact]
    public void TopIsDrawnAsRight()
    {
        var layout = Layout(ScreenEdge.Top, 200);

        Assert.Equal(ScreenEdge.Right, layout.Anchor.Edge);
        Assert.Equal(Work.Right, layout.ExpandedFrame.Right);
    }

    static PlacementLayout Layout(ScreenEdge edge, double offset) =>
        PlacementLayout.Create(new EdgeAnchor("m", edge, offset), Work, PanelSize.DefaultWidth, PanelSize.DefaultHeight);
}
