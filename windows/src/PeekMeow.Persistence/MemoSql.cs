namespace PeekMeow.Persistence;

/// Daily filters are half-open UTC instants. Do not wrap the column in DATE().
public static class MemoSql
{
    public const string DailyItems = """
        SELECT id, category_id, parent_id, type, title, body, is_completed, completed_at,
               sort_order, scheduled_date, due_date, is_archived, created_at, updated_at
        FROM memo_items
        WHERE parent_id IS NULL
          AND is_archived = 0
          AND scheduled_date >= @start
          AND scheduled_date < @next
          AND (@category IS NULL OR category_id = @category)
        ORDER BY sort_order
        """;

    public const string PastUnfinished = """
        SELECT id, category_id, parent_id, type, title, body, is_completed, completed_at,
               sort_order, scheduled_date, due_date, is_archived, created_at, updated_at
        FROM memo_items
        WHERE parent_id IS NULL
          AND type = 'task'
          AND is_archived = 0
          AND is_completed = 0
          AND scheduled_date < @start
          AND (@category IS NULL OR category_id = @category)
        ORDER BY scheduled_date DESC, sort_order ASC
        """;

    public const string NextRootOrder = """
        SELECT COALESCE(MAX(sort_order), -1) + 1
        FROM memo_items
        WHERE parent_id IS NULL
          AND scheduled_date >= @start
          AND scheduled_date < @next
        """;
}
