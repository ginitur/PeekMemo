using PeekMemo.Core.Daily;
using PeekMemo.Core.Layout;
using PeekMemo.Core.Models;
using Xunit;

namespace PeekMemo.Windows.Tests;

public class DailyQueryTests
{
    static readonly TimeZoneInfo Zone = TimeZoneInfo.Utc;
    static readonly DateTimeOffset Today = new(2026, 10, 1, 9, 0, 0, TimeSpan.Zero);
    static readonly DateTimeOffset Yesterday = Today.AddDays(-1);
    static readonly CivilDay TodayDay = CivilDay.From(Today, Zone);

    [Fact]
    public void DailyQueryReturnsThatDaysRootsOnly()
    {
        var work = Guid.NewGuid();
        var parent = MemoItem.Create(MemoItemType.Task, "Parent", Today, work, sortOrder: 1);
        var child = MemoItem.Create(MemoItemType.Task, "Child", Today, work, parent.Id, sortOrder: 0);
        var note = MemoItem.Create(MemoItemType.Note, "Note", Today, sortOrder: 2);
        var otherDay = MemoItem.Create(MemoItemType.Task, "Yesterday", Yesterday);

        var roots = DailyQuery.RootsOn([parent, child, note, otherDay], TodayDay, categoryId: null);

        Assert.Equal([parent.Id, note.Id], roots.Select(item => item.Id).ToArray());
        Assert.DoesNotContain(roots, item => item.Id == child.Id);
    }

    [Fact]
    public void CategoryFilterKeepsNullOnlyInAll()
    {
        var work = Guid.NewGuid();
        var personal = Guid.NewGuid();
        var workTask = MemoItem.Create(MemoItemType.Task, "Work", Today, work);
        var personalTask = MemoItem.Create(MemoItemType.Task, "Personal", Today, personal);
        var unlabeled = MemoItem.Create(MemoItemType.Task, "Loose", Today);

        var all = DailyQuery.RootsOn([workTask, personalTask, unlabeled], TodayDay, categoryId: null);
        var onlyWork = DailyQuery.RootsOn([workTask, personalTask, unlabeled], TodayDay, work);

        Assert.Equal(3, all.Count);
        Assert.Equal([workTask.Id], onlyWork.Select(item => item.Id).ToArray());
        Assert.Null(CategoryDisplay.Label(null));
    }

    [Fact]
    public void PastUnfinishedAppearsOnlyOnTodayAndDoesNotMoveTheDate()
    {
        var old = MemoItem.Create(MemoItemType.Task, "Old", Yesterday);
        var done = MemoItem.Create(MemoItemType.Task, "Done", Yesterday, isCompleted: true, completedAt: Today);
        var note = MemoItem.Create(MemoItemType.Note, "Note", Yesterday);
        var todayTask = MemoItem.Create(MemoItemType.Task, "Today", Today);

        var onToday = DailyQuery.PastUnfinished([old, done, note, todayTask], TodayDay, TodayDay);
        var onYesterday = DailyQuery.PastUnfinished([old], CivilDay.From(Yesterday, Zone), TodayDay);

        Assert.Equal([old.Id], onToday.Select(item => item.Id).ToArray());
        Assert.True(onToday[0].ScheduledDate == Yesterday);
        Assert.Empty(onYesterday);
    }

    [Fact]
    public void ProgressIgnoresNotesAndSubtasks()
    {
        var parent = MemoItem.Create(MemoItemType.Task, "Parent", Today, isCompleted: true, completedAt: Today);
        var note = MemoItem.Create(MemoItemType.Note, "Note", Today);
        var child = MemoItem.Create(MemoItemType.Task, "Child", Today, parentId: parent.Id, isCompleted: true, completedAt: Today);
        var roots = DailyQuery.RootsOn([parent, note, child], TodayDay, categoryId: null);

        var progress = DailyQuery.Progress(roots);

        Assert.Equal(1, progress.Completed);
        Assert.Equal(1, progress.Total);
        Assert.Equal(18d, LayoutMetrics.SubtaskIndent);
    }
}
