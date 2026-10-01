using PeekMemo.Core.Models;

namespace PeekMemo.Core.Daily;

public static class TaskHierarchy
{
    public static bool CanAddSubtask(MemoItem parent) =>
        parent.Type == MemoItemType.Task && parent.ParentId is null && !parent.IsArchived;
}
