using PeekMeow.Core.Daily;
using PeekMeow.Core.Models;
using Xunit;

namespace PeekMeow.Windows.Tests;

public class NoteTests
{
    static readonly DateOnly Today = new(2026, 10, 1);

    [Fact]
    public void ANoteIsListedWithoutACheckboxRoleOrProgress()
    {
        var board = MemoBoard.CreateDefaults(Today);
        board.TryAddNote("Remember to ask John about API", out var note);

        Assert.Equal(MemoItemType.Note, note!.Type);
        Assert.Contains(board.DailyItems, item => item.Id == note.Id);
        Assert.False(TaskHierarchy.CanAddSubtask(note));
        Assert.Null(board.DayProgress.Text);

        board.SetCompleted(note.Id, completed: true, DateTimeOffset.UnixEpoch);
        Assert.False(board.Items.Single(item => item.Id == note.Id).IsCompleted);
    }

    [Fact]
    public void AddTaskUsesTheSelectedFilterAndAddNoteCanBeUncategorized()
    {
        var board = MemoBoard.CreateDefaults(Today);
        var work = board.ActiveCategories.Single(category => category.Name == "Work").Id;
        board.SelectCategory(work);
        board.TryAddTask("Report", out var task);
        board.SelectCategory(null);
        board.TryAddNote("Loose", out var note);

        Assert.Equal(work, task!.CategoryId);
        Assert.Equal(Today, task.ScheduledDate);
        Assert.Null(note!.CategoryId);
    }
}
