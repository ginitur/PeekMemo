using PeekMemo.Core.Models;

namespace PeekMemo.Core.Persistence;

/// Write-through used by the in-memory board. The UI does not issue SQL.
public interface IBoardStore
{
    void InsertItem(MemoItem item);

    void UpdateItem(MemoItem item);

    void DeleteItem(Guid id);

    void SetCompleted(Guid id, bool completed, DateTimeOffset at);

    void InsertCategory(Category category);

    void UpdateCategory(Category category);

    void ReorderCategories(IReadOnlyList<Guid> orderedIds);
}
