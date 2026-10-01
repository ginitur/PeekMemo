using PeekMemo.Core.Daily;
using Xunit;

namespace PeekMemo.Windows.Tests;

public class DateNavigationTests
{
    static readonly DateOnly Today = new(2026, 10, 1);

    [Fact]
    public void ArrowsMoveAcrossSep30Oct1AndOct2()
    {
        var board = MemoBoard.CreateDefaults(Today);

        Assert.Equal(Today, board.SelectedDate);
        Assert.Equal("Oct 1 · Today", board.DateLabel);
        Assert.True(board.IsViewingToday);

        board.ShiftDate(-1);
        Assert.Equal(new DateOnly(2026, 9, 30), board.SelectedDate);
        Assert.Equal("Sep 30", board.DateLabel);
        Assert.False(board.IsViewingToday);

        board.ShiftDate(2);
        Assert.Equal(new DateOnly(2026, 10, 2), board.SelectedDate);
        Assert.Equal("Oct 2", board.DateLabel);

        board.SelectDate(Today);
        Assert.True(board.IsViewingToday);
    }

    [Fact]
    public void TodayIsADateComparisonNotACategory()
    {
        var board = MemoBoard.CreateDefaults(Today);
        board.SelectCategory(board.ActiveCategories[0].Id);
        board.ShiftDate(1);

        Assert.Equal("Work", board.FilterLabel);
        Assert.False(board.IsViewingToday);
    }
}
