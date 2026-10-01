using PeekMemo.Core.Daily;
using Xunit;

namespace PeekMemo.Windows.Tests;

public class CategoryFilterTests
{
    static readonly DateOnly Today = new(2026, 10, 1);

    [Fact]
    public void WorkTaskAppearsInAllAndWorkButNotPersonal()
    {
        var board = MemoBoard.CreateSample(Today);
        var work = board.ActiveCategories.Single(category => category.Name == "Work").Id;
        var personal = board.ActiveCategories.Single(category => category.Name == "Personal").Id;

        Assert.Contains(board.DailyItems, item => item.Title == "Prepare report");

        board.SelectCategory(work);
        Assert.Contains(board.DailyItems, item => item.Title == "Prepare report");
        Assert.DoesNotContain(board.DailyItems, item => item.Title == "Call the dentist");

        board.SelectCategory(personal);
        Assert.DoesNotContain(board.DailyItems, item => item.Title == "Prepare report");
        Assert.Contains(board.DailyItems, item => item.Title == "Call the dentist");
    }

    [Fact]
    public void NullCategoryAppearsOnlyInAllAndHasNoLabel()
    {
        var board = MemoBoard.CreateSample(Today);
        var note = board.DailyItems.Single(item => item.Title == "Remember API question");

        Assert.Null(note.CategoryId);
        Assert.Null(board.CategoryLabel(note));
        Assert.Null(board.SelectedCategoryId);
        Assert.Equal(CategoryFilterLabel.AllTasks, board.FilterLabel);
        Assert.DoesNotContain(board.ActiveCategories, category => category.Name is "All" or "All Tasks" or "Default" or "Uncategorized");

        board.SelectCategory(board.ActiveCategories[0].Id);
        Assert.DoesNotContain(board.DailyItems, item => item.CategoryId is null);
    }

    [Fact]
    public void NewAndRenamedCategoriesJoinTheFilter()
    {
        var board = MemoBoard.CreateDefaults(Today);
        Assert.True(board.TryAddCategory("Home", out var home));
        board.SelectCategory(home!.Id);
        board.TryAddTask("Water plants", out _);

        Assert.Equal("Home", board.FilterLabel);
        Assert.Equal([ "Water plants" ], board.DailyItems.Select(item => item.Title).ToArray());

        Assert.True(board.TryRenameCategory(home.Id, "House"));
        Assert.Equal("House", board.FilterLabel);
        board.SelectCategory(null);
        Assert.Equal("House", board.CategoryLabel(board.Items.Single()));
    }

    [Fact]
    public void FilteredPastUnfinishedUsesTheSameCategory()
    {
        var board = MemoBoard.CreateSample(Today);
        var personal = board.ActiveCategories.Single(category => category.Name == "Personal").Id;

        Assert.Contains(board.PastUnfinishedItems, item => item.Title == "Yesterday task");

        board.SelectCategory(personal);
        Assert.Empty(board.PastUnfinishedItems);
    }
}
