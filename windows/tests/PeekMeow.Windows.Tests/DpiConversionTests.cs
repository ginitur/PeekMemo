using PeekMeow.Core.Geometry;
using PeekMeow.Core.Layout;
using Xunit;

namespace PeekMeow.Windows.Tests;

public class DpiConversionTests
{
    [Theory]
    [InlineData(96u, 1)]
    [InlineData(120u, 1.25)]
    [InlineData(144u, 1.5)]
    [InlineData(168u, 1.75)]
    [InlineData(192u, 2)]
    public void ScaleIsDpiOver96(uint dpi, double factor)
    {
        Assert.Equal(factor, new DpiScale(dpi).Factor, 5);
    }

    [Fact]
    public void AMissingDpiDoesNotCollapseTheScale()
    {
        Assert.Equal(1d, new DpiScale(0).Factor);
        Assert.Equal(14, new DpiScale(0).ToPixels(14));
    }

    [Theory]
    [InlineData(96u, 14, 14)]
    [InlineData(144u, 14, 21)]
    [InlineData(192u, 14, 28)]
    [InlineData(96u, 22, 22)]
    [InlineData(144u, 22, 33)]
    [InlineData(192u, 22, 44)]
    public void HitAndGripStayConstantInDipsAndScaleInPixels(uint dpi, int dip, int pixels)
    {
        Assert.Equal(pixels, new DpiScale(dpi).ToPixels(dip));
        Assert.Equal(dip, new DpiScale(dpi).ToDip(pixels), 5);
    }

    [Fact]
    public void PanelWidthStays340DipsOnEverySyntheticMonitor()
    {
        foreach (var monitor in SyntheticMonitors.All)
        {
            var layout = PlacementLayout.Create(
                new EdgeAnchor(monitor.DeviceName, PeekMeow.Core.Models.ScreenEdge.Right, monitor.WorkingArea.Height / 2),
                monitor.WorkingArea,
                PanelSize.DefaultWidth,
                PanelSize.DefaultHeight);

            Assert.Equal(340d, layout.ContentFrame.Width, 3);
            Assert.Equal(14d, LayoutMetrics.HitThickness);
            Assert.Equal(monitor.Scale.ToPixels(340), monitor.Scale.ToPixels(layout.ContentFrame.Width));
        }

        Assert.Equal(340, SyntheticMonitors.A.Scale.ToPixels(340));
        Assert.Equal(510, SyntheticMonitors.B.Scale.ToPixels(340));
        Assert.Equal(680, SyntheticMonitors.C.Scale.ToPixels(340));
    }

    [Fact]
    public void MonitorScaleUsesTheSameFormula()
    {
        var direct = new DpiScale(192).ToDip(0, 0, 1920, 1040);
        var wrapped = MonitorScale.ToDip(0, 0, 1920, 1040, 192);

        Assert.Equal(direct, wrapped);
    }
}
