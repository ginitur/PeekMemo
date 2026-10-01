using PeekMeow.Core.Models;

namespace PeekMeow.Persistence;

public interface ICategoryRepository
{
    IReadOnlyList<Category> ListAll();

    IReadOnlyList<Category> ListActive();

    Category Create(string name, string? icon = null, string? color = null);

    void Insert(Category category);

    void Rename(Guid id, string name);

    void Archive(Guid id);

    void UpdateColor(Guid id, string? color);

    void Update(Category category);

    void Reorder(IReadOnlyList<Guid> orderedIds);

    /// Removes the row. Memo items keep their text and lose the category (ON DELETE SET NULL).
    void Delete(Guid id);
}
