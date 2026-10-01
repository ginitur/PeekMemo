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

/// <see cref="ScheduledDate"/> is the civil day the item belongs to, not a timestamp.
/// <see cref="CompletedAt"/> is the instant it was checked. Due date is unused by the panel.
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
    DateOnly ScheduledDate,
    DateOnly? DueDate,
    bool IsArchived,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt)
{
    public static MemoItem Create(
        MemoItemType type,
        string title,
        DateOnly scheduled,
        Guid? categoryId = null,
        Guid? parentId = null,
        int sortOrder = 0,
        bool isCompleted = false,
        DateTimeOffset? completedAt = null,
        bool isArchived = false,
        DateOnly? dueDate = null,
        Guid? id = null,
        string? body = null,
        DateTimeOffset? timestamp = null)
    {
        var stamp = timestamp ?? DateTimeOffset.UtcNow;
        return new MemoItem(
            id ?? Guid.NewGuid(),
            categoryId,
            parentId,
            type,
            title,
            body,
            isCompleted,
            completedAt,
            sortOrder,
            scheduled,
            dueDate,
            isArchived,
            stamp,
            stamp);
    }
}
