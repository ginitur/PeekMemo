using PeekMemo.Core.Layout;

namespace PeekMemo.Core.Geometry;

public readonly record struct MigrationResult(
    EdgeAnchor Anchor,
    MonitorDescriptor Monitor,
    bool Migrated,
    bool FoundMonitor);

public static class MonitorMigration
{
    public static MigrationResult Resolve(
        EdgeAnchor anchor,
        IReadOnlyList<MonitorDescriptor> monitors,
        double stackLength = LayoutMetrics.WedgeLength)
    {
        var normalized = anchor.Normalized();
        if (monitors.Count == 0)
        {
            return new MigrationResult(normalized, default, Migrated: false, FoundMonitor: false);
        }

        var migrated = normalized.Edge != anchor.Edge;
        MonitorDescriptor monitor;
        if (!TryFind(monitors, normalized.MonitorIdentifier, out monitor))
        {
            monitor = Primary(monitors);
            migrated = true;
        }

        var offset = EdgeGeometry.ClampOffset(normalized.Offset, normalized.Edge, monitor.WorkingArea, stackLength);
        if (Math.Abs(offset - normalized.Offset) > 0.01)
        {
            migrated = true;
        }

        var next = new EdgeAnchor(monitor.DeviceName, normalized.Edge, offset);
        if (!string.Equals(next.MonitorIdentifier, normalized.MonitorIdentifier, StringComparison.OrdinalIgnoreCase))
        {
            migrated = true;
        }

        return new MigrationResult(next, monitor, migrated, FoundMonitor: true);
    }

    public static MonitorDescriptor Primary(IReadOnlyList<MonitorDescriptor> monitors)
    {
        foreach (var monitor in monitors)
        {
            if (monitor.IsPrimary)
            {
                return monitor;
            }
        }

        return monitors[0];
    }

    static bool TryFind(IReadOnlyList<MonitorDescriptor> monitors, string deviceName, out MonitorDescriptor monitor)
    {
        if (!string.IsNullOrWhiteSpace(deviceName))
        {
            foreach (var candidate in monitors)
            {
                if (string.Equals(candidate.DeviceName, deviceName, StringComparison.OrdinalIgnoreCase))
                {
                    monitor = candidate;
                    return true;
                }
            }
        }

        monitor = default;
        return false;
    }
}
