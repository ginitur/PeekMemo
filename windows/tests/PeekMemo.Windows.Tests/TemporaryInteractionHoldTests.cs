using PeekMemo.Core.Hover;
using PeekMemo.Core.Interaction;
using Xunit;

namespace PeekMemo.Windows.Tests;

public class TemporaryInteractionHoldTests
{
    static readonly DateTimeOffset T0 = new(2026, 10, 1, 9, 0, 0, TimeSpan.Zero);

    [Fact]
    public void AMenuHoldBlocksCollapseAndReleaseRestartsTheCloseDelay()
    {
        var interaction = new PanelInteraction();
        var hover = interaction.Hover;
        hover.PointerEntered(T0);
        Assert.True(hover.Tick(T0.AddMilliseconds(160)));

        interaction.BeginHold();
        hover.PointerLeft(T0.AddMilliseconds(400));
        Assert.False(hover.Tick(T0.AddSeconds(30)));
        Assert.Equal(HoverPhase.Expanded, hover.Phase);
        Assert.Equal(PresentationMode.Peek, interaction.Mode);
        Assert.False(interaction.IsPinned);

        var released = T0.AddSeconds(1);
        interaction.EndHold(released);
        Assert.False(hover.Tick(released.AddMilliseconds(349)));
        Assert.True(hover.Tick(released.AddMilliseconds(350)));
        Assert.Equal(HoverPhase.Collapsed, hover.Phase);
    }

    [Fact]
    public void CheckboxHoldDoesNotPinOrEnterInteractive()
    {
        var interaction = new PanelInteraction();
        interaction.Hover.PointerEntered(T0);
        interaction.Hover.Tick(T0.AddMilliseconds(160));

        interaction.BeginHold();
        interaction.EndHold(T0.AddMilliseconds(200));

        Assert.Equal(PresentationMode.Peek, interaction.Mode);
        Assert.Equal(HoverPhase.Expanded, interaction.Hover.Phase);
        Assert.False(interaction.IsPinned);
    }

    [Fact]
    public void EndingAnEditorWhileThePointerIsOutsideStartsTheCloseDelay()
    {
        var interaction = new PanelInteraction();
        var hover = interaction.Hover;
        hover.PointerEntered(T0);
        hover.Tick(T0.AddMilliseconds(160));

        interaction.BeginInteractive();
        hover.PointerLeft(T0.AddMilliseconds(500));
        Assert.False(hover.Tick(T0.AddSeconds(30)));

        var released = T0.AddSeconds(2);
        interaction.EndInteractive(released);
        Assert.Equal(PresentationMode.Peek, interaction.Mode);
        Assert.False(interaction.IsPinned);
        Assert.True(hover.Tick(released.AddMilliseconds(350)));
        Assert.Equal(HoverPhase.Collapsed, hover.Phase);
    }
}
