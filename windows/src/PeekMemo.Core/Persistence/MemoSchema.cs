namespace PeekMemo.Core.Persistence;

/// Column names match the macOS SQLite schema. Windows does not add task columns.
public static class MemoSchema
{
    public const string CategoriesTable = "categories";
    public const string MemoItemsTable = "memo_items";

    public static readonly string[] CategoryColumns =
    [
        "id",
        "name",
        "icon",
        "color",
        "sort_order",
        "is_archived",
        "created_at",
        "updated_at"
    ];

    public static readonly string[] MemoItemColumns =
    [
        "id",
        "category_id",
        "parent_id",
        "type",
        "title",
        "body",
        "is_completed",
        "completed_at",
        "sort_order",
        "scheduled_date",
        "due_date",
        "is_archived",
        "created_at",
        "updated_at"
    ];
}
