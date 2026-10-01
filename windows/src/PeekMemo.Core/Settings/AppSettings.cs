using PeekMemo.Core.Geometry;
using PeekMemo.Core.Layout;
using PeekMemo.Core.Models;

namespace PeekMemo.Core.Settings;

public enum ThemePreference
{
    System,
    Light,
    Dark
}

/// Window placement is monitor + edge + offset. Absolute x/y are not stored.
public sealed class AppSettings
{
    public int Version { get; set; } = 1;
    public string Edge { get; set; } = ScreenEdge.Right.ToString();
    public double? EdgeOffset { get; set; }
    public string? MonitorDeviceName { get; set; }
    public PlacementSettings? Placement { get; set; }
    public double PanelWidth { get; set; } = PanelSize.DefaultWidth;
    public double PanelHeight { get; set; } = PanelSize.DefaultHeight;
    public double PanelOpacity { get; set; } = LayoutMetrics.PanelOpacity;
    public string Theme { get; set; } = ThemePreference.System.ToString();
    public double HoverOpenDelaySeconds { get; set; } = LayoutMetrics.HoverOpenDelaySeconds;
    public double HoverCloseDelaySeconds { get; set; } = LayoutMetrics.HoverCloseDelaySeconds;
    public bool ReduceMotion { get; set; }
    public bool LaunchAtStartup { get; set; }
    public double WedgeThickness { get; set; } = LayoutMetrics.VisibleWedgeThickness;
    public double WedgeLength { get; set; } = LayoutMetrics.WedgeLength;
    public double WedgeOpacity { get; set; } = LayoutMetrics.WedgeOpacity;

    public ScreenEdge ResolvedEdge()
    {
        if (!Enum.TryParse<ScreenEdge>(Edge, ignoreCase: true, out var edge))
        {
            return ScreenEdge.Right;
        }

        return PlacementPolicy.SupportedOrRight(edge);
    }

    public ThemePreference ResolvedTheme()
    {
        return Enum.TryParse<ThemePreference>(Theme, ignoreCase: true, out var theme)
            ? theme
            : ThemePreference.System;
    }

    /// Nested <see cref="Placement"/> wins. Flat fields remain so a Phase 1 file still loads.
    /// A null offset means the center of <paramref name="workingArea"/> and is not a stored coordinate.
    public EdgeAnchor ResolveAnchor(DipRect workingArea)
    {
        var edge = ResolvedPlacementEdge();
        var span = EdgeGeometry.Span(edge, workingArea);
        double offset;
        if (Placement?.Offset is double placed)
        {
            offset = placed;
        }
        else if (EdgeOffset is double flat)
        {
            offset = flat;
        }
        else
        {
            offset = span / 2;
        }

        return new EdgeAnchor(ResolvedMonitorId() ?? "", edge, offset);
    }

    public void WriteAnchor(EdgeAnchor anchor)
    {
        var normalized = anchor.Normalized();
        Edge = normalized.Edge.ToString();
        EdgeOffset = normalized.Offset;
        MonitorDeviceName = string.IsNullOrEmpty(normalized.MonitorIdentifier) ? null : normalized.MonitorIdentifier;
        Placement = new PlacementSettings
        {
            Monitor = MonitorDeviceName,
            Edge = normalized.Edge.ToString(),
            Offset = normalized.Offset
        };
    }

    public void WritePanelSize(double width, double height)
    {
        var stored = PanelSize.ClampStored(width, height);
        PanelWidth = stored.Width;
        PanelHeight = stored.Height;
    }

    public ScreenEdge ResolvedPlacementEdge()
    {
        var text = !string.IsNullOrWhiteSpace(Placement?.Edge) ? Placement!.Edge! : Edge;
        if (!Enum.TryParse<ScreenEdge>(text, ignoreCase: true, out var edge))
        {
            return ScreenEdge.Right;
        }

        return PlacementPolicy.SupportedOrRight(edge);
    }

    public string? ResolvedMonitorId()
    {
        if (!string.IsNullOrWhiteSpace(Placement?.Monitor))
        {
            return Placement!.Monitor;
        }

        return string.IsNullOrWhiteSpace(MonitorDeviceName) ? null : MonitorDeviceName;
    }
}
