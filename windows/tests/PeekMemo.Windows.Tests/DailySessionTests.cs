using PeekMemo.Core.Daily;
using PeekMemo.Core.Hover;
using PeekMemo.Core.Interaction;
using PeekMemo.Core.Models;
using Xunit;

namespace PeekMemo.Windows.Tests;

public class DailySessionTests
{
    static readonly DateTimeOffset T0 = new(2026, 10, 1, 9, 0, 0, TimeSpan.Zero);
    static readonly DateOnly Today = new(2026, 10, 1);
    static readonly DateOnly Yesterday = new(2026, 9, 30);
    static readonly DateOnly Tomorrow = new(2026, 10, 2);

    [Fact]
    public void AddTaskGoesInteractiveThenSaveReturnsToPeekWithoutPinning()
    {
        var session = Opened();
        var work = WorkId(session);

        session.SelectCategory(work);
        session.BeginAddTask();
        Assert.Equal(PresentationMode.Interactive, session.Interaction.Mode);
        Assert.False(session.Interaction.IsPinned);

        session.SetDraft("  Prepare report  ");
        Assert.False(session.SubmitKey(enter: true, control: false, escape: false, T0));

        Assert.Equal(PresentationMode.Peek, session.Interaction.Mode);
        Assert.False(session.Interaction.IsPinned);
        Assert.False(session.Interaction.Hover.InteractionHeld);
        var created = Assert.Single(session.Board.Items);
        Assert.Equal("Prepare report", created.Title);
        Assert.Equal(work, created.CategoryId);
        Assert.Equal(Today, created.ScheduledDate);
    }

    [Fact]
    public void AllFilterAddsAnUncategorizedTaskAndEscapeCancels()
    {
        var session = Opened();
        session.SelectCategory(null);
        session.BeginAddTask();
        session.SetDraft("Loose");
        session.SubmitKey(enter: true, control: true, escape: false, T0);
        Assert.Null(Assert.Single(session.Board.Items).CategoryId);

        session.BeginAddTask();
        session.SetDraft("Nope");
        session.SubmitKey(enter: false, control: false, escape: true, T0);
        Assert.Single(session.Board.Items);
        Assert.Equal(PresentationMode.Peek, session.Interaction.Mode);
    }

    [Fact]
    public void SwitchingEditorsDoesNotStackInteractiveDepth()
    {
        var session = Opened();
        session.BeginAddTask();
        session.BeginAddNote();
        session.SubmitKey(enter: false, control: false, escape: true, T0);

        Assert.Equal(PresentationMode.Peek, session.Interaction.Mode);
        Assert.False(session.Interaction.Hover.InteractionHeld);
        Assert.False(session.Interaction.IsPinned);
        Assert.Empty(session.Board.Items);
    }

    [Fact]
    public void DatePickerHoldDoesNotPinAndReleaseRestartsTheCloseDelay()
    {
        var session = Opened();
        session.OpenDatePicker();
        Assert.Equal(PresentationMode.Interactive, session.Interaction.Mode);
        Assert.False(session.Interaction.IsPinned);

        session.Interaction.Hover.PointerLeft(T0.AddMilliseconds(400));
        Assert.False(session.Interaction.Hover.Tick(T0.AddSeconds(30)));
        Assert.Equal(HoverPhase.Expanded, session.Interaction.Hover.Phase);

        var released = T0.AddSeconds(1);
        session.CloseDatePicker(released);
        Assert.Equal(PresentationMode.Peek, session.Interaction.Mode);
        Assert.False(session.Interaction.IsPinned);
        Assert.False(session.Interaction.Hover.Tick(released.AddMilliseconds(349)));
        Assert.True(session.Interaction.Hover.Tick(released.AddMilliseconds(350)));
        Assert.Equal(HoverPhase.Collapsed, session.Interaction.Hover.Phase);
    }

    [Fact]
    public void ClosingTheDatePickerWhileAnEditorIsOpenStaysInteractive()
    {
        var session = Opened();
        session.BeginAddTask();
        session.OpenDatePicker();
        session.CloseDatePicker(T0.AddSeconds(1));

        Assert.Equal(PresentationMode.Interactive, session.Interaction.Mode);
        Assert.True(session.EditorHoldsInteractive);
        Assert.False(session.DatePickerHoldsInteractive);
        Assert.False(session.Interaction.IsPinned);

        session.SubmitKey(enter: false, control: false, escape: true, T0.AddSeconds(2));
        Assert.Equal(PresentationMode.Peek, session.Interaction.Mode);
        Assert.False(session.Interaction.Hover.InteractionHeld);
    }

    [Fact]
    public void CategoryHoldSelectsAndDoesNotPin()
    {
        var session = Opened();
        var work = WorkId(session);

        session.BeginSurfaceHold();
        session.SelectCategory(work);
        Assert.Equal(PresentationMode.Peek, session.Interaction.Mode);
        Assert.Equal("Work", session.Board.FilterLabel);

        session.EndSurfaceHold(T0.AddMilliseconds(200));
        Assert.False(session.Interaction.IsPinned);
        Assert.Equal(HoverPhase.Expanded, session.Interaction.Hover.Phase);
        Assert.False(session.Interaction.Hover.InteractionHeld);
    }

    [Fact]
    public void CheckboxToggleStaysInPeekAndLeavesTheTaskInPlace()
    {
        var session = Opened();
        session.BeginAddTask();
        session.SetDraft("Call");
        session.SubmitKey(enter: true, control: false, escape: false, T0);
        var id = session.Board.Items.Single().Id;

        session.BeginSurfaceHold();
        session.ToggleCompleted(id, T0.AddMinutes(1));
        session.EndSurfaceHold(T0.AddMinutes(1));

        Assert.Equal(PresentationMode.Peek, session.Interaction.Mode);
        Assert.False(session.Interaction.IsPinned);
        var item = session.Board.DailyItems.Single();
        Assert.True(item.IsCompleted);
        Assert.Equal(Today, item.ScheduledDate);
        Assert.Equal("1/1", session.Board.DayProgress.Text);
    }

    [Fact]
    public void SubtaskEnterContinuesAndCtrlEnterClosesWithoutPinning()
    {
        var session = Opened();
        session.BeginAddTask();
        session.SetDraft("Parent");
        session.SubmitKey(enter: true, control: false, escape: false, T0);
        var parent = session.Board.Items.Single().Id;

        session.BeginAddSubtask(parent);
        session.SetDraft("One");
        Assert.True(session.SubmitKey(enter: true, control: false, escape: false, T0));
        Assert.Equal(EditorKind.NewSubtask, session.Editing.Kind);
        Assert.Equal("", session.Editing.Draft);
        Assert.Equal(PresentationMode.Interactive, session.Interaction.Mode);
        Assert.False(session.Interaction.IsPinned);

        session.SetDraft("Two");
        Assert.False(session.SubmitKey(enter: true, control: true, escape: false, T0));
        Assert.Equal(PresentationMode.Peek, session.Interaction.Mode);
        Assert.Equal(["One", "Two"], TaskHierarchy.Children(session.Board.Items, parent).Select(item => item.Title).ToArray());
        Assert.DoesNotContain(session.Board.DailyItems, item => item.ParentId is not null);
    }

    [Fact]
    public void EmptySubtaskBlurCancelsAndTitleBlurKeepsTheOldTitle()
    {
        var session = Opened();
        session.BeginAddTask();
        session.SetDraft("Parent");
        session.SubmitKey(enter: true, control: false, escape: false, T0);
        var parent = session.Board.Items.Single().Id;

        session.BeginAddSubtask(parent);
        session.SetDraft("   ");
        Assert.False(session.SubmitBlur(T0));
        Assert.Empty(TaskHierarchy.Children(session.Board.Items, parent));
        Assert.Equal(PresentationMode.Peek, session.Interaction.Mode);

        session.BeginTitle(parent);
        session.SetDraft("  ");
        session.SubmitBlur(T0);
        Assert.Equal("Parent", session.Board.Items.Single().Title);

        session.BeginTitle(parent);
        session.SetDraft("Renamed");
        session.SubmitKey(enter: true, control: false, escape: false, T0);
        Assert.Equal("Renamed", session.Board.Items.Single().Title);
    }

    [Fact]
    public void NoteIsListedAndExcludedFromProgress()
    {
        var session = Opened();
        session.BeginAddTask();
        session.SetDraft("Task");
        session.SubmitKey(enter: true, control: false, escape: false, T0);
        session.BeginAddNote();
        session.SetDraft("Remember API question");
        session.SubmitBlur(T0);

        Assert.Equal(2, session.Board.DailyItems.Count);
        Assert.Contains(session.Board.DailyItems, item => item.Type == MemoItemType.Note && item.Title == "Remember API question");
        Assert.Equal("0/1", session.Board.DayProgress.Text);
        var note = session.Board.Items.Single(item => item.Type == MemoItemType.Note);
        session.ToggleCompleted(note.Id, T0);
        Assert.False(session.Board.Items.Single(item => item.Id == note.Id).IsCompleted);
    }

    [Fact]
    public void CompletingTheParentCompletesChildrenAndDeleteRemovesThem()
    {
        var session = Opened();
        session.BeginAddTask();
        session.SetDraft("Parent");
        session.SubmitKey(enter: true, control: false, escape: false, T0);
        var parent = session.Board.Items.Single().Id;
        session.BeginAddSubtask(parent);
        session.SetDraft("Child");
        session.SubmitKey(enter: true, control: true, escape: false, T0);

        session.ToggleCompleted(parent, T0);
        Assert.All(session.Board.Items, item => Assert.True(item.IsCompleted));
        Assert.Contains(session.Board.DailyItems, item => item.Id == parent && item.IsCompleted);

        session.BeginAddSubtask(parent);
        session.Delete(parent, T0);
        Assert.Empty(session.Board.Items);
        Assert.Equal(PresentationMode.Peek, session.Interaction.Mode);
        Assert.False(session.Interaction.IsPinned);
    }

    [Fact]
    public void SampleDatesCategoriesAndPastUnfinishedFollowTheFilter()
    {
        var session = new DailySession(MemoBoard.CreateSample(Today), new PanelInteraction());
        Open(session.Interaction);

        Assert.Equal("Oct 1 · Today", session.Board.DateLabel);
        Assert.Equal("1/3", session.Board.DayProgress.Text);
        Assert.Contains(session.Board.PastUnfinishedItems, item => item.Title == "Yesterday task");
        Assert.DoesNotContain(session.Board.DailyItems, item => item.Title == "Tomorrow task");
        Assert.Null(session.Board.CategoryLabel(session.Board.Items.Single(item => item.Type == MemoItemType.Note)));

        session.ShiftDate(-1);
        Assert.Equal("Sep 30", session.Board.DateLabel);
        Assert.Empty(session.Board.PastUnfinishedItems);
        Assert.Contains(session.Board.DailyItems, item => item.Title == "Yesterday task" && !item.IsCompleted);

        session.SelectDate(Tomorrow);
        Assert.Equal("Oct 2", session.Board.DateLabel);
        Assert.Empty(session.Board.PastUnfinishedItems);
        Assert.Contains(session.Board.DailyItems, item => item.Title == "Tomorrow task");

        session.SelectDate(Today);
        session.SelectCategory(WorkId(session));
        Assert.Contains(session.Board.DailyItems, item => item.Title == "Prepare report");
        Assert.Contains(session.Board.PastUnfinishedItems, item => item.Title == "Yesterday task");
        Assert.DoesNotContain(session.Board.DailyItems, item => item.Title == "Call the dentist");
        Assert.DoesNotContain(session.Board.DailyItems, item => item.Type == MemoItemType.Note);
        Assert.Equal("0/1", session.Board.DayProgress.Text);

        var personal = session.Board.ActiveCategories.Single(category => category.Name == "Personal").Id;
        session.SelectCategory(personal);
        Assert.Empty(session.Board.PastUnfinishedItems);
        Assert.DoesNotContain(session.Board.DailyItems, item => item.Title == "Prepare report");
        Assert.Contains(session.Board.DailyItems, item => item.Title == "Finished task" && item.IsCompleted);
    }

    [Fact]
    public void NewAndRenamedCategoriesAppearWithoutPinning()
    {
        var session = Opened();
        session.BeginNewCategory();
        session.SetDraft("House");
        session.SubmitKey(enter: true, control: false, escape: false, T0);
        Assert.Contains(session.Board.ActiveCategories, category => category.Name == "House");
        Assert.Equal(PresentationMode.Peek, session.Interaction.Mode);
        Assert.False(session.Interaction.IsPinned);

        var house = session.Board.ActiveCategories.Single(category => category.Name == "House").Id;
        session.BeginRenameCategory(house);
        session.SetDraft("Home");
        session.SubmitBlur(T0);
        Assert.Contains(session.Board.ActiveCategories, category => category.Name == "Home");
        Assert.False(session.Interaction.IsPinned);
    }

    [Fact]
    public void PeekStyleKeepsTheToolWindowAndDoesNotMoveTheFrame()
    {
        var peeked = ActivationStyle.ForMode(0, peek: true);
        Assert.Equal(ActivationStyle.ToolWindow | ActivationStyle.NoActivate, peeked);

        var typing = ActivationStyle.ForMode(peeked, peek: false);
        Assert.Equal(ActivationStyle.ToolWindow, typing);
        Assert.Equal(0, typing & ActivationStyle.NoActivate);

        var preserved = ActivationStyle.ForMode(0x1, peek: true);
        Assert.Equal(0x1, preserved & 0x1);

        Assert.NotEqual(0u, ActivationStyle.FrameStable & ActivationStyle.NoMove);
        Assert.NotEqual(0u, ActivationStyle.FrameStable & ActivationStyle.NoSize);
        Assert.NotEqual(0u, ActivationStyle.FrameStable & ActivationStyle.NoZOrder);
        Assert.NotEqual(0u, ActivationStyle.FrameStable & ActivationStyle.FrameChanged);
        Assert.NotEqual(0u, ActivationStyle.FrameStable & ActivationStyle.NoActivatePosition);
        Assert.Equal(0u, ActivationStyle.FrameStable & 0x0040);
    }

    static DailySession Opened()
    {
        var session = new DailySession(MemoBoard.CreateDefaults(Today), new PanelInteraction());
        Open(session.Interaction);
        return session;
    }

    static void Open(PanelInteraction interaction)
    {
        interaction.Hover.PointerEntered(T0);
        Assert.True(interaction.Hover.Tick(T0.AddMilliseconds(160)));
    }

    static Guid WorkId(DailySession session) =>
        session.Board.ActiveCategories.Single(category => category.Name == "Work").Id;
}
