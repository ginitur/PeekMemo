using PeekMemo.Core.Hover;
using PeekMemo.Core.Interaction;
using PeekMemo.Core.Settings;

namespace PeekMemo.Windows.ViewModels;

public sealed class EdgeSession
{
    public PanelInteraction Interaction { get; } = new();
    public HoverEngine Hover => Interaction.Hover;
    public AppSettings Settings { get; private set; }
    public double LiveWidth { get; private set; }
    public double LiveHeight { get; private set; }

    public EdgeSession(AppSettings settings)
    {
        Settings = settings;
        LiveWidth = settings.PanelWidth;
        LiveHeight = settings.PanelHeight;
        ApplyDelays();
    }

    public void ReplaceSettings(AppSettings settings)
    {
        Settings = settings;
        LiveWidth = settings.PanelWidth;
        LiveHeight = settings.PanelHeight;
        ApplyDelays();
    }

    public void SetLiveSize(double width, double height)
    {
        LiveWidth = width;
        LiveHeight = height;
    }

    void ApplyDelays()
    {
        Hover.OpenDelay = TimeSpan.FromSeconds(Math.Max(0, Settings.HoverOpenDelaySeconds));
        Hover.CloseDelay = TimeSpan.FromSeconds(Math.Max(0, Settings.HoverCloseDelaySeconds));
    }
}
