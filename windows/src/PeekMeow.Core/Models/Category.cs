namespace PeekMeow.Core.Models;

public sealed record Category(
    Guid Id,
    string Name,
    string? Icon,
    string? Color,
    int SortOrder,
    bool IsArchived,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);

public static class CategoryDisplay
{
    /// A missing category has no label. The UI must not invent "Uncategorized".
    public static string? Label(Category? category) =>
        category is null || string.IsNullOrWhiteSpace(category.Name) ? null : category.Name;
}
