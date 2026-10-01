using PeekMeow.Core.Daily;
using PeekMeow.Core.Interaction;
using Xunit;

namespace PeekMeow.Windows.Tests;

public class CategoryMenuHoldTests
{
    static readonly DateOnly Today = new(2026, 10, 1);
    static readonly DateTimeOffset Now = new(2026, 10, 1, 9, 0, 0, TimeSpan.Zero);

    [Fact]
    public void OpeningAndClosingTheMenuHoldsWithoutPinning()
    {
        var session = new DailySession(MemoBoard.CreateDefaults(Today), new PanelInteraction());
        var work = session.Board.ActiveCategories.Single(category => category.Name == "Work").Id;

        Assert.Equal(0, session.Interaction.InteractionHoldCount);
        Assert.False(session.Interaction.IsPinned);
        Assert.Equal(CategoryFilterLabel.AllTasks, session.Board.FilterLabel);

        session.BeginSurfaceHold();
        Assert.Equal(1, session.Interaction.InteractionHoldCount);
        Assert.False(session.Interaction.IsPinned);

        session.SelectCategory(work);
        Assert.Equal("Work", session.Board.FilterLabel);
        session.EndSurfaceHold(Now);
        Assert.Equal(0, session.Interaction.InteractionHoldCount);
        Assert.False(session.Interaction.IsPinned);
        Assert.Equal(PresentationMode.Peek, session.Interaction.Mode);
    }

    [Fact]
    public void AddTaskUnderAllTasksLeavesCategoryEmpty()
    {
        var session = new DailySession(MemoBoard.CreateDefaults(Today), new PanelInteraction());
        Assert.Null(session.Board.SelectedCategoryId);
        session.BeginAddTask();
        session.SetDraft("Loose");
        session.SubmitKey(enter: true, control: false, escape: false, Now);
        var item = Assert.Single(session.Board.Items);
        Assert.Null(item.CategoryId);
        Assert.Null(session.Board.CategoryLabel(item));
        Assert.Equal(CategoryFilterLabel.AllTasks, session.Board.FilterLabel);
    }
}
