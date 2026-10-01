using PeekMeow.Core.Models;

namespace PeekMeow.Core.Daily;

public static class TaskHierarchy
{
    public static bool CanAddSubtask(MemoItem parent) =>
        parent.Type == MemoItemType.Task && parent.ParentId is null && !parent.IsArchived;

    public static IReadOnlyList<MemoItem> Children(IEnumerable<MemoItem> items, Guid parentId) =>
        items.Where(item => item.ParentId == parentId && !item.IsArchived)
            .OrderBy(item => item.SortOrder)
            .ToList();
}
