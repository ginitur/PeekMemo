using PeekMemo.Core.Daily;
using Xunit;

namespace PeekMemo.Windows.Tests;

public class ProgressTests
{
    static readonly DateOnly Today = new(2026, 10, 1);

    [Fact]
    public void ProgressCountsRootTasksOnly()
    {
        var board = MemoBoard.CreateSample(Today);

        Assert.Equal(1, board.DayProgress.Completed);
        Assert.Equal(3, board.DayProgress.Total);
        Assert.Equal("1/3", board.DayProgress.Text);
    }

    [Fact]
    public void ACategoryFilterChangesTheCount()
    {
        var board = MemoBoard.CreateSample(Today);
        board.SelectCategory(board.ActiveCategories.Single(category => category.Name == "Work").Id);

        Assert.Equal(0, board.DayProgress.Completed);
        Assert.Equal(1, board.DayProgress.Total);
    }

    [Fact]
    public void NotesAloneDoNotShowAFraction()
    {
        var board = MemoBoard.CreateDefaults(Today);
        board.TryAddNote("Remember", out _);

        Assert.Equal(0, board.DayProgress.Total);
        Assert.Null(board.DayProgress.Text);
    }
}
