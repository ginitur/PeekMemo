using PeekMemo.Core.Daily;
using Xunit;

namespace PeekMemo.Windows.Tests;

public class TaskCompletionTests
{
    static readonly DateOnly Today = new(2026, 10, 1);
    static readonly DateTimeOffset At = new(2026, 10, 1, 15, 0, 0, TimeSpan.Zero);

    [Fact]
    public void CompletingATaskLeavesItOnThatDay()
    {
        var board = MemoBoard.CreateDefaults(Today);
        board.TryAddTask("Ship", out var task);
        board.SetCompleted(task!.Id, completed: true, At);

        var shown = board.DailyItems.Single(item => item.Id == task.Id);
        Assert.True(shown.IsCompleted);
        Assert.Equal(At, shown.CompletedAt);
        Assert.Equal(Today, shown.ScheduledDate);
    }

    [Fact]
    public void ParentAndChildRulesStayInTheBoard()
    {
        var board = MemoBoard.CreateDefaults(Today);
        Assert.True(board.TryAddTask("Parent", out var parent));
        Assert.True(board.TryAddSubtask(parent!.Id, "A", out var first));
        Assert.True(board.TryAddSubtask(parent.Id, "B", out var second));
        Assert.NotNull(first);
        Assert.NotNull(second);

        board.SetCompleted(parent.Id, completed: true, At);
        Assert.All(board.Items.Where(item => item.Id == parent.Id || item.ParentId == parent.Id), item => Assert.True(item.IsCompleted));

        board.SetCompleted(parent.Id, completed: false, At);
        Assert.False(board.Items.Single(item => item.Id == parent.Id).IsCompleted);
        Assert.True(board.Items.Single(item => item.Id == first!.Id).IsCompleted);

        board.SetCompleted(first.Id, completed: false, At);
        Assert.False(board.Items.Single(item => item.Id == parent.Id).IsCompleted);

        board.SetCompleted(first.Id, completed: true, At);
        board.SetCompleted(second!.Id, completed: true, At);
        Assert.True(board.Items.Single(item => item.Id == parent.Id).IsCompleted);
    }
}
