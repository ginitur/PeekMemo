using PeekMeow.Core.Daily;
using PeekMeow.Core.Hover;
using PeekMeow.Core.Interaction;
using Xunit;

namespace PeekMeow.Windows.Tests;

public class InteractionModeTests
{
    static readonly DateTimeOffset T0 = new(2026, 10, 1, 9, 0, 0, TimeSpan.Zero);
    static readonly DateOnly Today = new(2026, 10, 1);

    [Fact]
    public void AddTaskGoesInteractiveThenSaveReturnsToPeekWithoutPinning()
    {
        var interaction = new PanelInteraction();
        var board = MemoBoard.CreateDefaults(Today);
        var editing = new EditingController();

        Assert.Equal(PresentationMode.Peek, interaction.Mode);
        Assert.False(interaction.IsPinned);

        editing.Begin(EditorKind.NewTask, null, "");
        interaction.BeginInteractive();
        Assert.Equal(PresentationMode.Interactive, interaction.Mode);
        Assert.True(interaction.Hover.InteractionHeld);
        Assert.NotEqual(HoverPhase.Pinned, interaction.Hover.Phase);

        editing.Draft = "Prepare report";
        Assert.False(editing.Apply(board, editing.Key(enter: true, control: false, escape: false)));
        interaction.EndInteractive(T0);

        Assert.Equal(PresentationMode.Peek, interaction.Mode);
        Assert.False(interaction.IsPinned);
        Assert.Contains(board.Items, item => item.Title == "Prepare report");
    }

    [Fact]
    public void DatePickerAndCategorySelectionDoNotPin()
    {
        var interaction = new PanelInteraction();
        Open(interaction);

        interaction.BeginInteractive();
        Assert.Equal(PresentationMode.Interactive, interaction.Mode);
        Assert.False(interaction.IsPinned);
        interaction.EndInteractive(T0.AddSeconds(1));
        Assert.Equal(PresentationMode.Peek, interaction.Mode);
        Assert.Equal(HoverPhase.Expanded, interaction.Hover.Phase);

        interaction.BeginHold();
        Assert.Equal(PresentationMode.Peek, interaction.Mode);
        interaction.EndHold(T0.AddSeconds(2));
        Assert.False(interaction.IsPinned);
        Assert.Equal(HoverPhase.Expanded, interaction.Hover.Phase);
    }

    static void Open(PanelInteraction interaction)
    {
        interaction.Hover.PointerEntered(T0);
        Assert.True(interaction.Hover.Tick(T0.AddMilliseconds(160)));
    }
}
