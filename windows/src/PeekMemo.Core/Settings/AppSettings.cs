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
}
