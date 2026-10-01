using PeekMemo.Core.Geometry;
using PeekMemo.Core.Models;
using Xunit;

namespace PeekMemo.Windows.Tests;

public class MonitorMigrationTests
{
    [Fact]
    public void AMissingMonitorMovesToThePrimaryAndKeepsALegalEdge()
    {
        var result = MonitorMigration.Resolve(
            new EdgeAnchor(@"\\.\DISPLAY9", ScreenEdge.Left, 180),
            SyntheticMonitors.All);

        Assert.True(result.Migrated);
        Assert.True(result.FoundMonitor);
        Assert.Equal(SyntheticMonitors.A.DeviceName, result.Anchor.MonitorIdentifier);
        Assert.Equal(SyntheticMonitors.A.DeviceName, result.Monitor.DeviceName);
        Assert.Equal(ScreenEdge.Left, result.Anchor.Edge);
        Assert.Equal(180d, result.Anchor.Offset);
    }

    [Fact]
    public void AnOffsetPastTheWorkingAreaIsClampedWithoutLeavingTheMonitor()
    {
        var result = MonitorMigration.Resolve(
            new EdgeAnchor(SyntheticMonitors.A.DeviceName, ScreenEdge.Right, 99999),
            SyntheticMonitors.All);

        Assert.True(result.Migrated);
        Assert.Equal(SyntheticMonitors.A.DeviceName, result.Anchor.MonitorIdentifier);
        Assert.InRange(result.Anchor.Offset, 0, SyntheticMonitors.A.WorkingArea.Height);
        Assert.True(result.Anchor.Offset < SyntheticMonitors.A.WorkingArea.Height);
        var layout = PlacementLayout.Create(result.Anchor, result.Monitor.WorkingArea, 340, 460);
        Assert.True(layout.CollapsedFrame.Bottom <= result.Monitor.WorkingArea.Bottom + 0.01);
    }

    [Fact]
    public void StoredTopMigratesToRightOnTheSameMonitor()
    {
        var result = MonitorMigration.Resolve(
            new EdgeAnchor(SyntheticMonitors.B.DeviceName.ToLowerInvariant(), ScreenEdge.Top, 40),
            SyntheticMonitors.All);

        Assert.True(result.Migrated);
        Assert.Equal(SyntheticMonitors.B.DeviceName, result.Monitor.DeviceName);
        Assert.Equal(ScreenEdge.Right, result.Anchor.Edge);
    }

    [Fact]
    public void AnInRangeAnchorIsNotRewritten()
    {
        var result = MonitorMigration.Resolve(
            new EdgeAnchor(SyntheticMonitors.C.DeviceName, ScreenEdge.Bottom, 400),
            SyntheticMonitors.All);

        Assert.False(result.Migrated);
        Assert.Equal(400d, result.Anchor.Offset);
        Assert.Equal(ScreenEdge.Bottom, result.Anchor.Edge);
    }

    [Fact]
    public void NoMonitorsLeavesTheAnchorUnmoved()
    {
        var anchor = new EdgeAnchor(@"\\.\DISPLAY1", ScreenEdge.Right, 10);
        var result = MonitorMigration.Resolve(anchor, []);

        Assert.False(result.FoundMonitor);
        Assert.False(result.Migrated);
        Assert.Equal(anchor, result.Anchor);
    }
}
