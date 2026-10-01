using PeekMeow.Core.Hover;
using PeekMeow.Core.Interaction;
using Xunit;

namespace PeekMeow.Windows.Tests;

public class PanelInteractionTests
{
    static readonly DateTimeOffset T0 = new(2026, 10, 1, 9, 0, 0, TimeSpan.Zero);

    [Fact]
    public void DragAndResizePauseCollapseThenTheCloseDelayResumes()
    {
        var interaction = new PanelInteraction();
        var hover = interaction.Hover;

        hover.PointerEntered(T0);
        Assert.Equal(HoverPhase.Collapsed, hover.Phase);
        Assert.Equal(InteractionActivity.Idle, interaction.Activity);
        Assert.True(hover.Tick(T0.AddMilliseconds(160)));
        Assert.Equal(HoverPhase.Expanded, hover.Phase);

        interaction.BeginDrag();
        Assert.Equal(InteractionActivity.Dragging, interaction.Activity);
        Assert.Equal(PresentationMode.Peek, interaction.Mode);
        hover.PointerLeft(T0.AddMilliseconds(200));
        Assert.False(hover.Tick(T0.AddSeconds(30)));
        Assert.Equal(HoverPhase.Expanded, hover.Phase);

        hover.PointerEntered(T0.AddMilliseconds(400));
        interaction.EndDrag(T0.AddMilliseconds(400));
        Assert.Equal(InteractionActivity.Idle, interaction.Activity);
        Assert.Equal(HoverPhase.Expanded, hover.Phase);
        Assert.False(hover.Tick(T0.AddSeconds(30)));

        interaction.BeginResize();
        hover.PointerLeft(T0.AddSeconds(1));
        Assert.False(hover.Tick(T0.AddSeconds(30)));
        Assert.Equal(HoverPhase.Expanded, hover.Phase);
        Assert.Equal(InteractionActivity.Resizing, interaction.Activity);

        var released = T0.AddSeconds(2);
        interaction.EndResize(released);
        Assert.Equal(InteractionActivity.Idle, interaction.Activity);
        Assert.False(hover.Tick(released.AddMilliseconds(349)));
        Assert.True(hover.Tick(released.AddMilliseconds(350)));
        Assert.Equal(HoverPhase.Collapsed, hover.Phase);
        Assert.Equal(PresentationMode.Peek, interaction.Mode);
    }

    [Fact]
    public void EnterLeaveEnterCancelsThePreviousClose()
    {
        var hover = new HoverEngine();
        hover.PointerEntered(T0);
        Assert.True(hover.Tick(T0.AddMilliseconds(160)));

        var left = T0.AddSeconds(1);
        hover.PointerLeft(left);
        var generationAtLeave = hover.Generation;
        hover.PointerEntered(left.AddMilliseconds(20));

        Assert.True(hover.Generation > generationAtLeave);
        Assert.Null(hover.NextTransitionAt);
        Assert.False(hover.Tick(left.AddSeconds(5)));
        Assert.Equal(HoverPhase.Expanded, hover.Phase);
    }

    [Fact]
    public void AFastSweepDoesNotOpen()
    {
        var hover = new HoverEngine();
        hover.PointerEntered(T0);
        hover.PointerLeft(T0.AddMilliseconds(40));

        Assert.False(hover.Tick(T0.AddMilliseconds(400)));
        Assert.Equal(HoverPhase.Collapsed, hover.Phase);
    }
}
