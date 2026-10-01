using PeekMeow.Core.Geometry;
using PeekMeow.Core.Models;
using Xunit;

namespace PeekMeow.Windows.Tests;

public class EdgeAnchorTests
{
    [Fact]
    public void AnchorStoresMonitorEdgeAndOffsetNotAScreenPoint()
    {
        var anchor = new EdgeAnchor(@"\\.\DISPLAY2", ScreenEdge.Bottom, 420);

        Assert.Equal(@"\\.\DISPLAY2", anchor.MonitorIdentifier);
        Assert.Equal(ScreenEdge.Bottom, anchor.Edge);
        Assert.Equal(420d, anchor.Offset);
        Assert.DoesNotContain("X", typeof(EdgeAnchor).GetProperties().Select(property => property.Name));
        Assert.DoesNotContain("Y", typeof(EdgeAnchor).GetProperties().Select(property => property.Name));
    }

    [Fact]
    public void StoredTopNormalizesToRightWithoutChangingOffset()
    {
        var anchor = new EdgeAnchor(@"\\.\DISPLAY1", ScreenEdge.Top, 80).Normalized();

        Assert.Equal(ScreenEdge.Right, anchor.Edge);
        Assert.Equal(80d, anchor.Offset);
        Assert.Equal(@"\\.\DISPLAY1", anchor.MonitorIdentifier);
    }

    [Fact]
    public void LeftAndRightOffsetIsDownFromTheWorkingTopAndBottomOffsetIsX()
    {
        var work = new DipRect(10, 30, 800, 600);
        var vertical = EdgeGeometry.AnchorPoint(ScreenEdge.Right, work, offset: 120);
        var left = EdgeGeometry.AnchorPoint(ScreenEdge.Left, work, offset: 120);
        var bottom = EdgeGeometry.AnchorPoint(ScreenEdge.Bottom, work, offset: 120);

        Assert.Equal(work.Right, vertical.X);
        Assert.Equal(work.Y + 120, vertical.Y);
        Assert.Equal(work.X, left.X);
        Assert.Equal(work.Y + 120, left.Y);
        Assert.Equal(work.X + 120, bottom.X);
        Assert.Equal(work.Bottom, bottom.Y);
    }
}
