using PeekMemo.Core.Geometry;
using PeekMemo.Core.Layout;
using PeekMemo.Core.Models;
using Xunit;

namespace PeekMemo.Windows.Tests;

public class ResizeAnchorTests
{
    static readonly DipRect Work = new(0, 0, 1920, 1040);

    [Fact]
    public void RightResizeKeepsMaxXAndTheOffset()
    {
        var anchor = new EdgeAnchor("m", ScreenEdge.Right, 520);
        var before = PlacementLayout.Create(anchor, Work, 340, 460);
        var requested = ResizeGeometry.Requested(340, 460, dx: -80, dy: 30, ScreenEdge.Right);
        var after = PlacementLayout.Create(anchor, Work, requested.Width, requested.Height);

        Assert.Equal(420d, requested.Width);
        Assert.Equal(490d, requested.Height);
        Assert.Equal(before.Anchor.Offset, after.Anchor.Offset);
        Assert.Equal(before.ExpandedFrame.Right, after.ExpandedFrame.Right);
        Assert.Equal(Work.Right, after.ExpandedFrame.Right);
        Assert.True(after.ContentFrame.Width > before.ContentFrame.Width);
        Assert.True(after.ContentFrame.X < before.ContentFrame.X);
    }

    [Fact]
    public void LeftResizeKeepsMinXAndTheOffset()
    {
        var anchor = new EdgeAnchor("m", ScreenEdge.Left, 520);
        var before = PlacementLayout.Create(anchor, Work, 340, 460);
        var requested = ResizeGeometry.Requested(340, 460, dx: 70, dy: -20, ScreenEdge.Left);
        var after = PlacementLayout.Create(anchor, Work, requested.Width, requested.Height);

        Assert.Equal(before.ExpandedFrame.X, after.ExpandedFrame.X);
        Assert.Equal(Work.X, after.ExpandedFrame.X);
        Assert.Equal(520d, after.Anchor.Offset);
        Assert.Equal(410d, after.ContentFrame.Width);
        Assert.Equal(440d, after.ContentFrame.Height);
    }

    [Fact]
    public void BottomResizeKeepsTheBottomEdgeAndTheOffset()
    {
        var anchor = new EdgeAnchor("m", ScreenEdge.Bottom, 700);
        var before = PlacementLayout.Create(anchor, Work, 340, 460);
        var requested = ResizeGeometry.Requested(340, 460, dx: 40, dy: -50, ScreenEdge.Bottom);
        var after = PlacementLayout.Create(anchor, Work, requested.Width, requested.Height);

        Assert.Equal(before.ExpandedFrame.Bottom, after.ExpandedFrame.Bottom);
        Assert.Equal(Work.Bottom, after.ExpandedFrame.Bottom);
        Assert.Equal(700d, after.Anchor.Offset);
        Assert.Equal(510d, after.ContentFrame.Height);
        Assert.True(after.ContentFrame.Y < before.ContentFrame.Y);
    }

    [Fact]
    public void ScreenClampIsLiveOnlyAndTheStoredSizeKeepsTheRequest()
    {
        var tiny = new DipRect(0, 0, 200, 400);
        var requested = ResizeGeometry.Requested(340, 460, dx: -200, dy: 0, ScreenEdge.Right);
        var displayed = ResizeGeometry.ForDisplay(requested.Width, requested.Height, ScreenEdge.Right, tiny);
        var stored = ResizeGeometry.ForStore(requested.Width, requested.Height);

        Assert.Equal(540d, stored.Width);
        Assert.Equal(460d, stored.Height);
        Assert.True(displayed.Width < PanelSize.MinimumWidth);
        Assert.Equal(tiny.Width - LayoutMetrics.HitThickness, displayed.Width);
        Assert.Equal((280d, 300d), ResizeGeometry.ForStore(100, 100));
        Assert.Equal((PanelSize.AbsoluteMaximum, PanelSize.AbsoluteMaximum), ResizeGeometry.ForStore(9000, 9000));
    }
}
