using PeekMeow.Core.Models;

namespace PeekMeow.Core.Daily;

public readonly record struct DailyProgress(int Completed, int Total)
{
    public string? Text => Total > 0 ? $"{Completed}/{Total}" : null;
}

public static class DailyQuery
{
    public static IReadOnlyList<MemoItem> GetDailyItems(
        IEnumerable<MemoItem> items,
        DateOnly day,
        Guid? categoryId)
    {
        return items
            .Where(item => item.ParentId is null && !item.IsArchived)
            .Where(item => item.ScheduledDate == day)
            .Where(item => Matches(item, categoryId))
            .OrderBy(item => item.SortOrder)
            .ToList();
    }

    /// Past unfinished root tasks. Only when the selected day is today.
    /// Does not change <see cref="MemoItem.ScheduledDate"/>. Notes and subtasks are excluded.
    public static IReadOnlyList<MemoItem> GetPastUnfinished(
        IEnumerable<MemoItem> items,
        DateOnly selected,
        DateOnly today,
        Guid? categoryId = null)
    {
        if (selected != today)
        {
            return [];
        }

        return items
            .Where(item => item.ParentId is null)
            .Where(item => item.Type == MemoItemType.Task)
            .Where(item => !item.IsCompleted && !item.IsArchived)
            .Where(item => item.ScheduledDate < today)
            .Where(item => Matches(item, categoryId))
            .OrderByDescending(item => item.ScheduledDate)
            .ThenBy(item => item.SortOrder)
            .ToList();
    }

    /// Root tasks on that day. Notes and subtasks do not count.
    public static DailyProgress GetProgress(
        IEnumerable<MemoItem> items,
        DateOnly day,
        Guid? categoryId)
    {
        var tasks = GetDailyItems(items, day, categoryId)
            .Where(item => item.Type == MemoItemType.Task)
            .ToList();
        return new DailyProgress(tasks.Count(task => task.IsCompleted), tasks.Count);
    }

    public static DailyProgress GetProgress(IEnumerable<MemoItem> roots)
    {
        var tasks = roots.Where(item => item.Type == MemoItemType.Task && item.ParentId is null).ToList();
        return new DailyProgress(tasks.Count(task => task.IsCompleted), tasks.Count);
    }

    public static bool Matches(MemoItem item, Guid? categoryId) =>
        categoryId is null || item.CategoryId == categoryId;
}
