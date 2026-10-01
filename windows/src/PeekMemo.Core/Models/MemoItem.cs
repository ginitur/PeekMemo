namespace PeekMemo.Core.Models;

public enum MemoItemType
{
    Task,
    Note
}

public static class MemoTypeNames
{
    public const string Task = "task";
    public const string Note = "note";

    public static string ToStorage(MemoItemType type) => type switch
    {
        MemoItemType.Task => Task,
        MemoItemType.Note => Note,
        _ => throw new ArgumentOutOfRangeException(nameof(type), type, "Unknown memo type.")
    };
}

public sealed record MemoItem(
    Guid Id,
    Guid? CategoryId,
    Guid? ParentId,
    MemoItemType Type,
    string Title,
    string? Body,
    bool IsCompleted,
    DateTimeOffset? CompletedAt,
    int SortOrder,
    DateTimeOffset? ScheduledDate,
    DateTimeOffset? DueDate,
    bool IsArchived,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt)
{
    public static MemoItem Create(
        MemoItemType type,
        string title,
        DateTimeOffset scheduled,
        Guid? categoryId = null,
        Guid? parentId = null,
        int sortOrder = 0,
        bool isCompleted = false,
        DateTimeOffset? completedAt = null,
        bool isArchived = false,
        DateTimeOffset? dueDate = null,
        Guid? id = null)
    {
        return new MemoItem(
            id ?? Guid.NewGuid(),
            categoryId,
            parentId,
            type,
            title,
            Body: null,
            isCompleted,
            completedAt,
            sortOrder,
            scheduled,
            dueDate,
            isArchived,
            scheduled,
            scheduled);
    }
}
