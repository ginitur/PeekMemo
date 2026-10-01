using PeekMeow.Core.Models;

namespace PeekMeow.Core.Daily;

public static class CompletionRules
{
    public static IReadOnlyList<MemoItem> SetCompleted(
        IReadOnlyList<MemoItem> items,
        Guid id,
        bool completed,
        DateTimeOffset completedAt)
    {
        var current = items.ToDictionary(item => item.Id);
        if (!current.TryGetValue(id, out var target) || target.Type == MemoItemType.Note)
        {
            return items;
        }

        var next = new Dictionary<Guid, MemoItem>(current);
        Mark(next, target, completed, completedAt);

        if (completed && target.ParentId is null)
        {
            foreach (var child in items.Where(item => item.ParentId == target.Id && item.Type == MemoItemType.Task))
            {
                Mark(next, child, true, completedAt);
            }
        }

        if (target.ParentId is Guid parentId && next.TryGetValue(parentId, out var parent))
        {
            if (!completed)
            {
                Mark(next, parent, false, completedAt);
            }
            else
            {
                var children = items.Where(item => item.ParentId == parentId && item.Type == MemoItemType.Task).ToList();
                if (children.Count > 0 && children.All(child => next[child.Id].IsCompleted))
                {
                    Mark(next, parent, true, completedAt);
                }
            }
        }

        return items.Select(item => next[item.Id]).ToList();
    }

    static void Mark(Dictionary<Guid, MemoItem> next, MemoItem item, bool completed, DateTimeOffset completedAt)
    {
        next[item.Id] = item with
        {
            IsCompleted = completed,
            CompletedAt = completed ? completedAt : null,
            UpdatedAt = completedAt
        };
    }
}
