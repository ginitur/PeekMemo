using PeekMemo.Core.Daily;
using Xunit;

namespace PeekMemo.Windows.Tests;

public class EditingStateTests
{
    static readonly DateOnly Today = new(2026, 10, 1);

    [Fact]
    public void EnterAndBlurSaveATaskAndEscapeCancels()
    {
        var board = MemoBoard.CreateDefaults(Today);
        var editing = new EditingController();

        editing.Begin(EditorKind.NewTask, null, "  Report  ");
        Assert.False(editing.Apply(board, editing.Key(enter: true, control: false, escape: false)));
        Assert.Contains(board.Items, item => item.Title == "Report");
        Assert.False(editing.IsOpen);

        editing.Begin(EditorKind.NewTask, null, "");
        Assert.False(editing.Apply(board, editing.Key(enter: false, control: false, escape: true)));
        Assert.Single(board.Items);

        editing.Begin(EditorKind.NewTask, null, "");
        Assert.False(editing.Apply(board, editing.Blur()));
        Assert.Single(board.Items);

        editing.Begin(EditorKind.NewTask, null, "Blurred");
        Assert.False(editing.Apply(board, editing.Blur()));
        Assert.Contains(board.Items, item => item.Title == "Blurred");
    }

    [Fact]
    public void SubtaskEnterKeepsABlankFieldAndCtrlEnterCloses()
    {
        var board = MemoBoard.CreateDefaults(Today);
        board.TryAddTask("Parent", out var parent);
        var editing = new EditingController();

        editing.Begin(EditorKind.NewSubtask, parent!.Id, "One");
        Assert.True(editing.Apply(board, editing.Key(enter: true, control: false, escape: false)));
        Assert.Equal(EditorKind.NewSubtask, editing.Kind);
        Assert.Equal("", editing.Draft);

        editing.Draft = "Two";
        Assert.False(editing.Apply(board, editing.Key(enter: true, control: true, escape: false)));
        Assert.False(editing.IsOpen);
        Assert.Equal(["One", "Two"], TaskHierarchy.Children(board.Items, parent.Id).Select(item => item.Title).ToArray());
    }

    [Fact]
    public void EmptySubtaskBlurCancelsAndTitleBlurKeepsTheOldTitle()
    {
        var board = MemoBoard.CreateDefaults(Today);
        board.TryAddTask("Parent", out var parent);
        var editing = new EditingController();

        editing.Begin(EditorKind.NewSubtask, parent!.Id, "   ");
        Assert.False(editing.Apply(board, editing.Blur()));
        Assert.Empty(TaskHierarchy.Children(board.Items, parent.Id));

        editing.Begin(EditorKind.Title, parent.Id, "   ");
        Assert.False(editing.Apply(board, editing.Blur()));
        Assert.Equal("Parent", board.Items.Single(item => item.Id == parent.Id).Title);

        editing.Begin(EditorKind.Title, parent.Id, "Renamed");
        editing.Apply(board, editing.Key(enter: true, control: true, escape: false));
        Assert.Equal("Renamed", board.Items.Single(item => item.Id == parent.Id).Title);
    }
}
