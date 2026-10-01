using PeekMeow.Core.Daily;
using PeekMeow.Core.Layout;
using PeekMeow.Core.Models;
using Xunit;

namespace PeekMeow.Windows.Tests;

public class DailyQueryTests
{
    static readonly DateOnly TodayDate = new(2026, 10, 1);
    static readonly DateOnly YesterdayDate = new(2026, 9, 30);
    static readonly DateTimeOffset Stamp = new(2026, 10, 1, 9, 0, 0, TimeSpan.Zero);

    [Fact]
    public void DailyQueryReturnsThatDaysRootsOnly()
    {
        var work = Guid.NewGuid();
        var parent = MemoItem.Create(MemoItemType.Task, "Parent", TodayDate, work, sortOrder: 1);
        var child = MemoItem.Create(MemoItemType.Task, "Child", TodayDate, work, parent.Id, sortOrder: 0);
        var note = MemoItem.Create(MemoItemType.Note, "Note", TodayDate, sortOrder: 2);
        var otherDay = MemoItem.Create(MemoItemType.Task, "Yesterday", YesterdayDate);

        var roots = DailyQuery.GetDailyItems([parent, child, note, otherDay], TodayDate, categoryId: null);

        Assert.Equal([parent.Id, note.Id], roots.Select(item => item.Id).ToArray());
        Assert.DoesNotContain(roots, item => item.Id == child.Id);
    }

    [Fact]
    public void CategoryFilterKeepsNullOnlyInAll()
    {
        var work = Guid.NewGuid();
        var personal = Guid.NewGuid();
        var workTask = MemoItem.Create(MemoItemType.Task, "Work", TodayDate, work);
        var personalTask = MemoItem.Create(MemoItemType.Task, "Personal", TodayDate, personal);
        var unlabeled = MemoItem.Create(MemoItemType.Task, "Loose", TodayDate);

        var all = DailyQuery.GetDailyItems([workTask, personalTask, unlabeled], TodayDate, categoryId: null);
        var onlyWork = DailyQuery.GetDailyItems([workTask, personalTask, unlabeled], TodayDate, work);

        Assert.Equal(3, all.Count);
        Assert.Equal([workTask.Id], onlyWork.Select(item => item.Id).ToArray());
        Assert.Null(CategoryDisplay.Label(null));
    }

    [Fact]
    public void PastUnfinishedAppearsOnlyOnTodayAndDoesNotMoveTheDate()
    {
        var old = MemoItem.Create(MemoItemType.Task, "Old", YesterdayDate);
        var done = MemoItem.Create(MemoItemType.Task, "Done", YesterdayDate, isCompleted: true, completedAt: Stamp);
        var note = MemoItem.Create(MemoItemType.Note, "Note", YesterdayDate);
        var todayTask = MemoItem.Create(MemoItemType.Task, "Today", TodayDate);

        var onToday = DailyQuery.GetPastUnfinished([old, done, note, todayTask], TodayDate, TodayDate);
        var onYesterday = DailyQuery.GetPastUnfinished([old], YesterdayDate, TodayDate);

        Assert.Equal([old.Id], onToday.Select(item => item.Id).ToArray());
        Assert.Equal(YesterdayDate, onToday[0].ScheduledDate);
        Assert.Empty(onYesterday);
    }

    [Fact]
    public void ProgressIgnoresNotesAndSubtasks()
    {
        var parent = MemoItem.Create(MemoItemType.Task, "Parent", TodayDate, isCompleted: true, completedAt: Stamp);
        var note = MemoItem.Create(MemoItemType.Note, "Note", TodayDate);
        var child = MemoItem.Create(MemoItemType.Task, "Child", TodayDate, parentId: parent.Id, isCompleted: true, completedAt: Stamp);
        var roots = DailyQuery.GetDailyItems([parent, note, child], TodayDate, categoryId: null);

        var progress = DailyQuery.GetProgress(roots);

        Assert.Equal(1, progress.Completed);
        Assert.Equal(1, progress.Total);
        Assert.Equal(18d, LayoutMetrics.SubtaskIndent);
    }
}
