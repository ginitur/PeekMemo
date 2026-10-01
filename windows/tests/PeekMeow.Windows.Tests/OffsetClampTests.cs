using PeekMeow.Core.Geometry;
using PeekMeow.Core.Layout;
using PeekMeow.Core.Models;
using Xunit;

namespace PeekMeow.Windows.Tests;

public class OffsetClampTests
{
    static readonly DipRect Work = new(0, 0, 1000, 800);

    [Fact]
    public void VerticalOffsetStaysAHalfWedgeInsideTheWorkingHeight()
    {
        var half = LayoutMetrics.WedgeLength / 2;

        Assert.Equal(half, EdgeGeometry.ClampOffset(-40, ScreenEdge.Left, Work, LayoutMetrics.WedgeLength));
        Assert.Equal(half, EdgeGeometry.ClampOffset(0, ScreenEdge.Right, Work, LayoutMetrics.WedgeLength));
        Assert.Equal(Work.Height - half, EdgeGeometry.ClampOffset(5000, ScreenEdge.Right, Work, LayoutMetrics.WedgeLength));
        Assert.Equal(400d, EdgeGeometry.ClampOffset(400, ScreenEdge.Left, Work, LayoutMetrics.WedgeLength));
    }

    [Fact]
    public void BottomOffsetStaysAHalfWedgeInsideTheWorkingWidth()
    {
        var half = LayoutMetrics.WedgeLength / 2;

        Assert.Equal(half, EdgeGeometry.ClampOffset(1, ScreenEdge.Bottom, Work, LayoutMetrics.WedgeLength));
        Assert.Equal(Work.Width - half, EdgeGeometry.ClampOffset(9000, ScreenEdge.Bottom, Work, LayoutMetrics.WedgeLength));
        Assert.Equal(250d, EdgeGeometry.ClampOffset(250, ScreenEdge.Bottom, Work, LayoutMetrics.WedgeLength));
    }

    [Fact]
    public void ASpanShorterThanTheWedgeUsesTheMidpoint()
    {
        var tiny = new DipRect(0, 0, 100, 40);

        Assert.Equal(20d, EdgeGeometry.ClampOffset(0, ScreenEdge.Right, tiny, LayoutMetrics.WedgeLength));
        Assert.Equal(15d, EdgeGeometry.ClampOffset(0, ScreenEdge.Bottom, new DipRect(0, 0, 30, 400), LayoutMetrics.WedgeLength));
    }

    [Fact]
    public void ANonFiniteOffsetCentersInsteadOfLeavingTheWorkArea()
    {
        Assert.Equal(400d, EdgeGeometry.ClampOffset(double.NaN, ScreenEdge.Right, Work, LayoutMetrics.WedgeLength));
        Assert.Equal(500d, EdgeGeometry.ClampOffset(double.PositiveInfinity, ScreenEdge.Bottom, Work, LayoutMetrics.WedgeLength));
    }
}
