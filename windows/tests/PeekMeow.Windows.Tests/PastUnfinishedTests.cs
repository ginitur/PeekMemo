using PeekMeow.Core.Daily;
using PeekMeow.Core.Models;
using Xunit;

namespace PeekMeow.Windows.Tests;

public class PastUnfinishedTests
{
    static readonly DateOnly Sep30 = new(2026, 9, 30);
    static readonly DateOnly Oct1 = new(2026, 10, 1);
    static readonly DateOnly Oct2 = new(2026, 10, 2);

    [Fact]
    public void UnfinishedSep30AppearsOnOct1ButNotWhenViewingThatDayOrTheFuture()
    {
        var board = MemoBoard.CreateDefaults(Oct1);
        board.SelectDate(Sep30);
        board.TryAddTask("Outline", out _);
        board.SelectDate(Oct1);

        Assert.Equal(["Outline"], board.PastUnfinishedItems.Select(item => item.Title).ToArray());
        Assert.Equal(Sep30, board.Items.Single(item => item.Title == "Outline").ScheduledDate);
        Assert.DoesNotContain(board.DailyItems, item => item.Title == "Outline");

        board.SelectDate(Sep30);
        Assert.Empty(board.PastUnfinishedItems);
        Assert.Contains(board.DailyItems, item => item.Title == "Outline" && !item.IsCompleted);

        board.SelectDate(Oct2);
        Assert.Empty(board.PastUnfinishedItems);
        Assert.DoesNotContain(board.DailyItems, item => item.Title == "Outline");
    }

    [Fact]
    public void CompletedAndNotesDoNotEnterPastUnfinished()
    {
        var items = new[]
        {
            MemoItem.Create(MemoItemType.Task, "Done", Sep30, isCompleted: true),
            MemoItem.Create(MemoItemType.Note, "Old note", Sep30),
            MemoItem.Create(MemoItemType.Task, "Open", Sep30)
        };

        var past = DailyQuery.GetPastUnfinished(items, Oct1, Oct1);

        Assert.Equal(["Open"], past.Select(item => item.Title).ToArray());
    }
}
