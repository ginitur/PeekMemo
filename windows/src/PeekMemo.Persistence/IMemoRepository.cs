using PeekMemo.Core.Models;

namespace PeekMemo.Persistence;

public interface IMemoRepository
{
    IReadOnlyList<MemoItem> ListAll();

    IReadOnlyList<MemoItem> QueryDaily(DateOnly day, Guid? categoryId);

    IReadOnlyList<MemoItem> QueryPastUnfinished(DateOnly today, Guid? categoryId);

    MemoItem CreateTask(string title, DateOnly scheduled, Guid? categoryId, int? sortOrder = null);

    MemoItem CreateNote(string title, DateOnly scheduled, Guid? categoryId, string? body = null);

    MemoItem CreateSubtask(Guid parentId, string title);

    void Insert(MemoItem item);

    void Update(MemoItem item);

    void Delete(Guid id);

    /// Parent and child completion changes commit together.
    void SetCompleted(Guid id, bool completed, DateTimeOffset at);
}
