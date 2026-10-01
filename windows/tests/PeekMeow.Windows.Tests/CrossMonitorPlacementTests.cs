using PeekMeow.Core.Geometry;
using PeekMeow.Core.Layout;
using PeekMeow.Core.Models;
using Xunit;

namespace PeekMeow.Windows.Tests;

public class CrossMonitorPlacementTests
{
    [Fact]
    public void SyntheticMonitorsKeepDistinctWorkingAreas()
    {
        Assert.Equal(1920d, SyntheticMonitors.A.WorkingArea.Width);
        Assert.Equal(1040d, SyntheticMonitors.A.WorkingArea.Height);
        Assert.Equal(1080d, SyntheticMonitors.A.Bounds.Height);

        Assert.Equal(1280d, SyntheticMonitors.B.WorkingArea.X, 4);
        Assert.Equal(2560d / 1.5, SyntheticMonitors.B.WorkingArea.Width, 4);
        Assert.Equal(1392d / 1.5, SyntheticMonitors.B.WorkingArea.Height, 4);

        Assert.Equal(580d, SyntheticMonitors.C.WorkingArea.Y, 4);
        Assert.Equal(1890d, SyntheticMonitors.C.WorkingArea.Width, 4);
        Assert.True(SyntheticMonitors.C.WorkingArea.Right < SyntheticMonitors.C.Bounds.Right);
    }

    [Fact]
    public void TheSameDipPointCanFallOnTwoMonitorsSoSelectionUsesPixels()
    {
        Assert.True(SyntheticMonitors.A.Bounds.ContainsPoint(1500, 100));
        Assert.True(SyntheticMonitors.B.Bounds.ContainsPoint(1500, 100));

        Assert.True(MonitorDescriptor.TryContaining(SyntheticMonitors.All, 1500, 100, out var onA));
        Assert.Equal(SyntheticMonitors.A.DeviceName, onA.DeviceName);

        Assert.True(MonitorDescriptor.TryContaining(SyntheticMonitors.All, 2250, 100, out var onB));
        Assert.Equal(SyntheticMonitors.B.DeviceName, onB.DeviceName);

        Assert.True(MonitorDescriptor.TryContaining(SyntheticMonitors.All, 100, 1200, out var onC));
        Assert.Equal(SyntheticMonitors.C.DeviceName, onC.DeviceName);
    }

    [Fact]
    public void ARightEdgeDragReleasedOnTheNextMonitorSnapsToItsLeftEdge()
    {
        var pixelX = SyntheticMonitors.B.PixelWorkingArea.Left + 8;
        var pixelY = (SyntheticMonitors.B.PixelWorkingArea.Top + SyntheticMonitors.B.PixelWorkingArea.Bottom) / 2;
        Assert.True(MonitorDescriptor.TryContaining(SyntheticMonitors.All, pixelX, pixelY, out var monitor));

        var dipX = monitor.Scale.ToDip(pixelX);
        var dipY = monitor.Scale.ToDip(pixelY);
        var live = DragGeometry.Live(dipX, dipY, monitor.WorkingArea);
        var commit = DragGeometry.Commit(dipX, dipY, monitor.WorkingArea);
        var layout = PlacementLayout.Create(
            new EdgeAnchor(monitor.DeviceName, commit.Edge, commit.Offset),
            monitor.WorkingArea,
            PanelSize.DefaultWidth,
            PanelSize.DefaultHeight);

        Assert.Equal(SyntheticMonitors.B.DeviceName, monitor.DeviceName);
        Assert.Equal(ScreenEdge.Left, live.Edge);
        Assert.True(live.Snapped);
        Assert.Equal(ScreenEdge.Left, commit.Edge);
        Assert.Equal(monitor.WorkingArea.X, layout.ExpandedFrame.X);
        Assert.Equal(340d, layout.ContentFrame.Width, 3);
        Assert.Equal(21, monitor.Scale.ToPixels(LayoutMetrics.HitThickness));
    }

    [Fact]
    public void LiveDragDoesNotSnapFromTheMiddleAndCommitStillPicksALegalEdge()
    {
        var work = SyntheticMonitors.A.WorkingArea;
        var middle = DragGeometry.Live(work.X + work.Width / 2, work.Y + 200, work);
        var commit = DragGeometry.Commit(work.X + work.Width / 2, work.Y + 2, work);
        var onEdge = DragGeometry.Live(work.Right - LayoutMetrics.SnapThreshold, work.Y + 400, work);
        var outside = DragGeometry.Live(work.Right - LayoutMetrics.SnapThreshold - 1, work.Y + 400, work);

        Assert.False(middle.Snapped);
        Assert.NotEqual(work.Right, middle.Frame.Right);
        Assert.NotEqual(ScreenEdge.Top, commit.Edge);
        Assert.True(commit.Snapped);
        Assert.True(onEdge.Snapped);
        Assert.Equal(ScreenEdge.Right, onEdge.Edge);
        Assert.Equal(work.Right, onEdge.Frame.Right);
        Assert.False(outside.Snapped);
        Assert.NotEqual(work.Right, outside.Frame.Right);
    }

    [Fact]
    public void ClickAndDragSeparateAtSixDips()
    {
        Assert.False(PointerGesture.PastDragThreshold(5.9, 0));
        Assert.False(PointerGesture.PastDragThreshold(3, 4));
        Assert.True(PointerGesture.PastDragThreshold(6, 0));
        Assert.True(PointerGesture.PastDragThreshold(0, -6));
        Assert.Equal(24d, LayoutMetrics.SnapThreshold);
    }

    [Fact]
    public void ARightWedgeOnMonitorCUsesTheWorkingEdgeNotTheFullBounds()
    {
        var monitor = SyntheticMonitors.C;
        var layout = PlacementLayout.Create(
            new EdgeAnchor(monitor.DeviceName, ScreenEdge.Right, 200),
            monitor.WorkingArea,
            340,
            460);

        Assert.Equal(monitor.WorkingArea.Right, layout.ExpandedFrame.Right, 3);
        Assert.True(layout.ExpandedFrame.Right < monitor.Bounds.Right - 1);
        Assert.Equal(340d, layout.ContentFrame.Width, 3);
    }
}
