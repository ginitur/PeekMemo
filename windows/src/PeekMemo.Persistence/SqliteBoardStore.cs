using PeekMemo.Core.Models;
using PeekMemo.Core.Persistence;

namespace PeekMemo.Persistence;

public sealed class SqliteBoardStore : IBoardStore
{
    readonly MemoDatabase _database;

    public SqliteBoardStore(MemoDatabase database)
    {
        _database = database;
    }

    public void InsertItem(MemoItem item) => _database.Memos.Insert(item);

    public void UpdateItem(MemoItem item) => _database.Memos.Update(item);

    public void DeleteItem(Guid id) => _database.Memos.Delete(id);

    public void SetCompleted(Guid id, bool completed, DateTimeOffset at) =>
        _database.Memos.SetCompleted(id, completed, at);

    public void InsertCategory(Category category) => _database.Categories.Insert(category);

    public void UpdateCategory(Category category) => _database.Categories.Update(category);

    public void ReorderCategories(IReadOnlyList<Guid> orderedIds) => _database.Categories.Reorder(orderedIds);
}
