using PeekMemo.Core.Geometry;
using PeekMemo.Core.Hover;
using PeekMemo.Core.Layout;
using PeekMemo.Core.Models;
using PeekMemo.Core.Settings;

namespace PeekMemo.Windows.ViewModels;

public sealed class EdgeSession
{
    public HoverEngine Hover { get; } = new();
    public AppSettings Settings { get; private set; }

    public EdgeSession(AppSettings settings)
    {
        Settings = settings;
        ApplyDelays(settings);
    }

    public void ReplaceSettings(AppSettings settings)
    {
        Settings = settings;
        ApplyDelays(settings);
    }

    public DipRect FrameFor(DipRect workingArea)
    {
        var offset = EdgePlacement.ResolveOffset(Settings.EdgeOffset, workingArea.Height);
        var open = Hover.Phase is HoverPhase.Expanded or HoverPhase.Pinned;
        return open
            ? EdgePlacement.ExpandedFrame(
                workingArea,
                ScreenEdge.Right,
                offset,
                Settings.PanelWidth,
                Settings.PanelHeight)
            : EdgePlacement.CollapsedHitRect(
                workingArea,
                ScreenEdge.Right,
                offset,
                LayoutMetrics.HitThickness,
                Settings.WedgeLength);
    }

    void ApplyDelays(AppSettings settings)
    {
        Hover.OpenDelay = TimeSpan.FromSeconds(Math.Max(0, settings.HoverOpenDelaySeconds));
        Hover.CloseDelay = TimeSpan.FromSeconds(Math.Max(0, settings.HoverCloseDelaySeconds));
    }
}
