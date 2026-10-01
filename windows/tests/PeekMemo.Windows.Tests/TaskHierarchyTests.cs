using PeekMemo.Core.Daily;
using PeekMemo.Core.Layout;
using Xunit;

namespace PeekMemo.Windows.Tests;

public class TaskHierarchyTests
{
    static readonly DateOnly Today = new(2026, 10, 1);
    static readonly DateTimeOffset At = new(2026, 10, 1, 8, 0, 0, TimeSpan.Zero);

    [Fact]
    public void SubtasksUseTheParentDayAndAreNotDailyRoots()
    {
        var board = MemoBoard.CreateDefaults(Today, At);
        board.TryAddTask("Parent", out var parent);
        Assert.True(board.TryAddSubtask(parent!.Id, "Child", out var child));

        Assert.Equal(parent.ScheduledDate, child!.ScheduledDate);
        Assert.Equal(parent.Id, child.ParentId);
        Assert.Equal(18d, LayoutMetrics.SubtaskIndent);
        Assert.DoesNotContain(board.DailyItems, item => item.Id == child.Id);
    }

    [Fact]
    public void DeletingAChildLeavesTheParent()
    {
        var board = MemoBoard.CreateSample(Today, At);
        var child = board.Items.Single(item => item.Title == "Write draft");

        Assert.True(board.Delete(child.Id));
        Assert.Contains(board.Items, item => item.Title == "Prepare report");
        Assert.DoesNotContain(board.Items, item => item.Title == "Write draft");
    }
}
