using PeekMemo.Core.Models;

namespace PeekMemo.Core.Daily;

public readonly record struct DailyProgress(int Completed, int Total);

public static class DailyQuery
{
    public static IReadOnlyList<MemoItem> RootsOn(
        IEnumerable<MemoItem> items,
        CivilDay day,
        Guid? categoryId)
    {
        return items
            .Where(item => item.ParentId is null && !item.IsArchived)
            .Where(item => item.ScheduledDate is DateTimeOffset scheduled && day.Contains(scheduled))
            .Where(item => categoryId is null || item.CategoryId == categoryId)
            .OrderBy(item => item.SortOrder)
            .ToList();
    }

    /// Past unfinished root tasks, and only when the selected day is today.
    /// Does not change `scheduledDate`.
    public static IReadOnlyList<MemoItem> PastUnfinished(
        IEnumerable<MemoItem> items,
        CivilDay selected,
        CivilDay today)
    {
        if (selected.Date != today.Date)
        {
            return [];
        }

        return items
            .Where(item => item.ParentId is null)
            .Where(item => item.Type == MemoItemType.Task)
            .Where(item => !item.IsCompleted && !item.IsArchived)
            .Where(item => item.ScheduledDate is DateTimeOffset scheduled && CivilDay.From(scheduled, today.Zone).Date < today.Date)
            .OrderByDescending(item => item.ScheduledDate)
            .ThenBy(item => item.SortOrder)
            .ToList();
    }

    public static DailyProgress Progress(IEnumerable<MemoItem> roots)
    {
        var tasks = roots.Where(item => item.Type == MemoItemType.Task && item.ParentId is null).ToList();
        return new DailyProgress(tasks.Count(task => task.IsCompleted), tasks.Count);
    }
}
