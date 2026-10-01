using PeekMeow.Core.Daily;
using PeekMeow.Core.Models;
using Xunit;

namespace PeekMeow.Windows.Tests;

public class DailyViewTests
{
    static readonly DateOnly Today = new(2026, 10, 1);
    static readonly DateTimeOffset At = new(2026, 10, 1, 9, 0, 0, TimeSpan.Zero);

    [Fact]
    public void SampleShowsTodayRootsAndKeepsCompletedInPlace()
    {
        var board = MemoBoard.CreateSample(Today, At);
        var titles = board.DailyItems.Select(item => item.Title).ToArray();

        Assert.Equal(
            ["Prepare report", "Call the dentist", "Finished task", "Remember API question"],
            titles);
        Assert.Contains(board.DailyItems, item => item.Title == "Finished task" && item.IsCompleted);
        Assert.DoesNotContain(board.DailyItems, item => item.Title == "Collect data");
        Assert.DoesNotContain(board.DailyItems, item => item.Title == "Tomorrow task");
    }

    [Fact]
    public void SubtasksStayUnderTheParentAndCannotNestAgain()
    {
        var board = MemoBoard.CreateSample(Today, At);
        var parent = board.Items.Single(item => item.Title == "Prepare report");
        var children = TaskHierarchy.Children(board.Items, parent.Id);

        Assert.Equal(["Collect data", "Write draft"], children.Select(item => item.Title).ToArray());
        Assert.False(board.TryAddSubtask(children[0].Id, "Too deep", out _));
        Assert.Equal(2, TaskHierarchy.Children(board.Items, parent.Id).Count);
    }

    [Fact]
    public void DeletingAParentDeletesItsSubtasks()
    {
        var board = MemoBoard.CreateSample(Today, At);
        var parent = board.Items.Single(item => item.Title == "Prepare report");

        Assert.True(board.Delete(parent.Id));
        Assert.DoesNotContain(board.Items, item => item.Id == parent.Id || item.ParentId == parent.Id);
        Assert.Contains(board.Items, item => item.Title == "Call the dentist");
    }
}
