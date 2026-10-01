using PeekMemo.Core.Geometry;
using PeekMemo.Core.Layout;
using PeekMemo.Core.Models;
using Xunit;

namespace PeekMemo.Windows.Tests;

public class EdgePlacementTests
{
    static readonly DipRect Work = new(0, 0, 1280, 720);

    [Fact]
    public void RightWedgeUsesTheWorkingEdgeAndALargerHitRect()
    {
        var hit = EdgePlacement.CollapsedHitRect(Work, ScreenEdge.Right, anchorOffset: 360);
        var visible = EdgePlacement.VisibleWedge(hit, ScreenEdge.Right);

        Assert.Equal(Work.Right, hit.Right);
        Assert.Equal(LayoutMetrics.HitThickness, hit.Width);
        Assert.Equal(LayoutMetrics.WedgeLength, hit.Height);
        Assert.Equal(LayoutMetrics.VisibleWedgeThickness, visible.Width);
        Assert.True(visible.Width < hit.Width);
        Assert.Equal(hit.Right, visible.Right);
        Assert.True(hit.Width <= 16);
        Assert.True(visible.Width is >= 3 and <= 4);
    }

    [Fact]
    public void WedgeStaysInsideTheWorkingAreaWhenTheTaskbarInsetsIt()
    {
        var screenBottom = 1080;
        var work = new DipRect(0, 0, 1920, 1040);
        var hit = EdgePlacement.CollapsedHitRect(work, ScreenEdge.Right, anchorOffset: 900, length: 56);

        Assert.True(hit.Bottom <= work.Bottom);
        Assert.True(hit.Bottom < screenBottom);
        Assert.Equal(work.Right, hit.Right);
    }

    [Fact]
    public void LeftWedgeRespectsALeftTaskbar()
    {
        var work = new DipRect(60, 0, 1800, 1040);
        var hit = EdgePlacement.CollapsedHitRect(work, ScreenEdge.Left, anchorOffset: 200);

        Assert.Equal(60d, hit.X);
        Assert.True(hit.Right <= work.Right);
    }

    [Fact]
    public void BottomWedgeSitsOnTheWorkingBottom()
    {
        var work = new DipRect(0, 0, 1920, 1040);
        var hit = EdgePlacement.CollapsedHitRect(work, ScreenEdge.Bottom, anchorOffset: 400);

        Assert.Equal(work.Bottom, hit.Bottom);
        Assert.Equal(LayoutMetrics.HitThickness, hit.Height);
        Assert.True(hit.Right <= work.Right);
    }

    [Fact]
    public void TopIsNotASnapTarget()
    {
        var hit = EdgePlacement.CollapsedHitRect(Work, ScreenEdge.Top, anchorOffset: 100);

        Assert.Equal(Work.Right, hit.Right);
        Assert.Equal(LayoutMetrics.HitThickness, hit.Width);
    }

    [Fact]
    public void ExpandedPanelContainsTheCollapsedHitRect()
    {
        foreach (var edge in new[] { ScreenEdge.Right, ScreenEdge.Left, ScreenEdge.Bottom })
        {
            var offset = edge == ScreenEdge.Bottom ? Work.Width / 2 : Work.Height / 2;
            var hit = EdgePlacement.CollapsedHitRect(Work, edge, offset);
            var expanded = EdgePlacement.ExpandedFrame(Work, edge, offset);

            Assert.True(expanded.Contains(hit), edge.ToString());
            Assert.True(expanded.Right <= Work.Right + 0.01);
            Assert.True(expanded.Bottom <= Work.Bottom + 0.01);
        }
    }

    [Fact]
    public void MonitorScaleUsesWorkAreaPixelsNotAHardCodedResolution()
    {
        var dip = MonitorScale.ToDip(left: 0, top: 0, right: 1920, bottom: 1040, dpi: 96);

        Assert.Equal(1920d, dip.Width);
        Assert.Equal(1040d, dip.Height);
        Assert.NotEqual(1080, dip.Height);
    }

    [Fact]
    public void MonitorScaleDividesByDpi()
    {
        var dip = MonitorScale.ToDip(0, 0, 1920, 1040, dpi: 192);

        Assert.Equal(960d, dip.Width);
        Assert.Equal(520d, dip.Height);
    }
}
