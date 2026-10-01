using PeekMemo.Core.Models;
using PeekMemo.Core.Persistence;

namespace PeekMemo.Core.Daily;

/// In-memory memo state. <see cref="CreateSample"/> is a design fixture and is not written to SQLite.
public sealed class MemoBoard
{
    readonly List<Category> _categories = [];
    readonly List<MemoItem> _items = [];
    readonly DateTimeOffset _createdAt;

    /// When set, mutations are written through. A failed write restores the previous lists.
    public IBoardStore? Store { get; set; }

    public void Load(IEnumerable<Category> categories, IEnumerable<MemoItem> items)
    {
        _categories.Clear();
        _categories.AddRange(categories);
        _items.Clear();
        _items.AddRange(items);
    }

    public MemoBoard(DateOnly today, DateTimeOffset? createdAt = null)
    {
        Today = today;
        SelectedDate = today;
        _createdAt = createdAt ?? DateTimeOffset.UtcNow;
    }

    public DateOnly Today { get; }
    public DateOnly SelectedDate { get; private set; }
    public Guid? SelectedCategoryId { get; private set; }
    public bool IsViewingToday => SelectedDate == Today;
    public IReadOnlyList<Category> Categories => _categories;
    public IReadOnlyList<MemoItem> Items => _items;

    public IReadOnlyList<Category> ActiveCategories =>
        _categories.Where(category => !category.IsArchived).OrderBy(category => category.SortOrder).ToList();

    public IReadOnlyList<MemoItem> DailyItems =>
        DailyQuery.GetDailyItems(_items, SelectedDate, SelectedCategoryId);

    public IReadOnlyList<MemoItem> PastUnfinishedItems =>
        DailyQuery.GetPastUnfinished(_items, SelectedDate, Today, SelectedCategoryId);

    public DailyProgress DayProgress =>
        DailyQuery.GetProgress(_items, SelectedDate, SelectedCategoryId);

    public string DateLabel => DateTitle.Format(SelectedDate, IsViewingToday);

    public string FilterLabel =>
        SelectedCategoryId is Guid id
            ? ActiveCategories.FirstOrDefault(category => category.Id == id)?.Name ?? "All"
            : "All";

    public void SelectDate(DateOnly date) => SelectedDate = date;

    public void ShiftDate(int days) => SelectedDate = SelectedDate.AddDays(days);

    public void SelectCategory(Guid? categoryId)
    {
        if (categoryId is Guid id && ActiveCategories.All(category => category.Id != id))
        {
            return;
        }

        SelectedCategoryId = categoryId;
    }

    public bool TryAddTask(string title, out MemoItem? created) =>
        TryAddRoot(MemoItemType.Task, title, SelectedCategoryId, out created);

    public bool TryAddNote(string title, out MemoItem? created) =>
        TryAddRoot(MemoItemType.Note, title, SelectedCategoryId, out created);

    public bool TryAddSubtask(Guid parentId, string title, out MemoItem? created)
    {
        created = null;
        var text = title.Trim();
        if (text.Length == 0 || !_items.Exists(item => item.Id == parentId))
        {
            return false;
        }

        var parent = _items.First(item => item.Id == parentId);
        if (!TaskHierarchy.CanAddSubtask(parent))
        {
            return false;
        }

        var item = MemoItem.Create(
            MemoItemType.Task,
            text,
            parent.ScheduledDate,
            parent.CategoryId,
            parent.Id,
            NextChildOrder(parent.Id),
            timestamp: _createdAt);
        if (!Mutate(() => _items.Add(item), () => Store!.InsertItem(item)))
        {
            return false;
        }

        created = item;
        return true;
    }

    public bool TryRename(Guid id, string title)
    {
        var text = title.Trim();
        var index = _items.FindIndex(item => item.Id == id);
        if (text.Length == 0 || index < 0)
        {
            return false;
        }

        var updated = _items[index] with { Title = text, UpdatedAt = _createdAt };
        return Mutate(() => _items[index] = updated, () => Store!.UpdateItem(updated));
    }

    public bool Delete(Guid id)
    {
        if (_items.All(item => item.Id != id))
        {
            return false;
        }

        return Mutate(() =>
        {
            var doomed = new HashSet<Guid> { id };
            var grew = true;
            while (grew)
            {
                grew = false;
                foreach (var item in _items)
                {
                    if (item.ParentId is Guid parent && doomed.Contains(parent) && doomed.Add(item.Id))
                    {
                        grew = true;
                    }
                }
            }

            _items.RemoveAll(item => doomed.Contains(item.Id));
        }, () => Store!.DeleteItem(id));
    }

    public void SetCompleted(Guid id, bool completed, DateTimeOffset at)
    {
        Mutate(() =>
        {
            var next = CompletionRules.SetCompleted(_items.ToList(), id, completed, at);
            _items.Clear();
            _items.AddRange(next);
        }, () => Store!.SetCompleted(id, completed, at));
    }

    public bool TryAddCategory(string name, out Category? created)
    {
        created = null;
        var text = name.Trim();
        if (text.Length == 0)
        {
            return false;
        }

        var order = _categories.Count == 0 ? 0 : _categories.Max(category => category.SortOrder) + 1;
        var category = new Category(
            Guid.NewGuid(),
            text,
            Icon: null,
            Color: Palette[order % Palette.Length],
            order,
            IsArchived: false,
            _createdAt,
            _createdAt);
        if (!Mutate(() => _categories.Add(category), () => Store!.InsertCategory(category)))
        {
            return false;
        }

        created = category;
        return true;
    }

    public bool TryRenameCategory(Guid id, string name)
    {
        var text = name.Trim();
        var index = _categories.FindIndex(category => category.Id == id && !category.IsArchived);
        if (text.Length == 0 || index < 0)
        {
            return false;
        }

        var updated = _categories[index] with { Name = text, UpdatedAt = _createdAt };
        return Mutate(() => _categories[index] = updated, () => Store!.UpdateCategory(updated));
    }

    public bool TryArchiveCategory(Guid id)
    {
        var index = _categories.FindIndex(category => category.Id == id && !category.IsArchived);
        if (index < 0)
        {
            return false;
        }

        var updated = _categories[index] with { IsArchived = true, UpdatedAt = _createdAt };
        if (!Mutate(() => _categories[index] = updated, () => Store!.UpdateCategory(updated)))
        {
            return false;
        }

        if (SelectedCategoryId == id)
        {
            SelectedCategoryId = null;
        }

        return true;
    }

    public bool TryRecolorCategory(Guid id, string? color)
    {
        var index = _categories.FindIndex(category => category.Id == id);
        if (index < 0)
        {
            return false;
        }

        var updated = _categories[index] with { Color = color, UpdatedAt = _createdAt };
        return Mutate(() => _categories[index] = updated, () => Store!.UpdateCategory(updated));
    }

    public bool TryReorderCategories(IReadOnlyList<Guid> orderedIds)
    {
        var updated = _categories.Select(category =>
        {
            var position = -1;
            for (var index = 0; index < orderedIds.Count; index++)
            {
                if (orderedIds[index] == category.Id)
                {
                    position = index;
                    break;
                }
            }

            return position < 0 ? category : category with { SortOrder = position, UpdatedAt = _createdAt };
        }).ToList();
        return Mutate(() =>
        {
            _categories.Clear();
            _categories.AddRange(updated);
        }, () => Store!.ReorderCategories(orderedIds));
    }

    public string? CategoryLabel(MemoItem item)
    {
        if (SelectedCategoryId is not null || item.CategoryId is not Guid id)
        {
            return null;
        }

        var category = _categories.FirstOrDefault(candidate => candidate.Id == id && !candidate.IsArchived);
        return CategoryDisplay.Label(category);
    }

    public string? CategoryColor(MemoItem item)
    {
        if (item.CategoryId is not Guid id)
        {
            return null;
        }

        return _categories.FirstOrDefault(category => category.Id == id && !category.IsArchived)?.Color;
    }

    public static MemoBoard CreateDefaults(DateOnly today, DateTimeOffset? createdAt = null)
    {
        var board = new MemoBoard(today, createdAt);
        board.TryAddCategory("Work", out _);
        board.TryAddCategory("Personal", out _);
        return board;
    }

    /// In-memory fixtures for the panel. Do not write these rows into SQLite.
    public static MemoBoard CreateSample(DateOnly today, DateTimeOffset? createdAt = null)
    {
        var board = CreateDefaults(today, createdAt);
        var work = board.ActiveCategories.First(category => category.Name == "Work").Id;
        var personal = board.ActiveCategories.First(category => category.Name == "Personal").Id;
        var yesterday = today.AddDays(-1);
        var tomorrow = today.AddDays(1);

        board.AddRaw(MemoItemType.Task, "Yesterday task", yesterday, work, sortOrder: 0);
        var parent = board.AddRaw(MemoItemType.Task, "Prepare report", today, work, sortOrder: 0);
        board.AddRaw(MemoItemType.Task, "Collect data", today, work, parent.Id, sortOrder: 0, isCompleted: true, completedAt: board._createdAt);
        board.AddRaw(MemoItemType.Task, "Write draft", today, work, parent.Id, sortOrder: 1);
        board.AddRaw(MemoItemType.Task, "Call the dentist", today, personal, sortOrder: 1);
        board.AddRaw(MemoItemType.Task, "Finished task", today, personal, sortOrder: 2, isCompleted: true, completedAt: board._createdAt);
        board.AddRaw(MemoItemType.Note, "Remember API question", today, categoryId: null, sortOrder: 3);
        board.AddRaw(MemoItemType.Task, "Tomorrow task", tomorrow, work, sortOrder: 0);
        return board;
    }

    MemoItem AddRaw(
        MemoItemType type,
        string title,
        DateOnly day,
        Guid? categoryId,
        Guid? parentId = null,
        int sortOrder = 0,
        bool isCompleted = false,
        DateTimeOffset? completedAt = null)
    {
        var item = MemoItem.Create(
            type,
            title,
            day,
            categoryId,
            parentId,
            sortOrder,
            isCompleted,
            completedAt,
            timestamp: _createdAt);
        _items.Add(item);
        return item;
    }

    bool TryAddRoot(MemoItemType type, string title, Guid? categoryId, out MemoItem? created)
    {
        created = null;
        var text = title.Trim();
        if (text.Length == 0)
        {
            return false;
        }

        var item = MemoItem.Create(
            type,
            text,
            SelectedDate,
            categoryId,
            sortOrder: NextRootOrder(SelectedDate),
            timestamp: _createdAt);
        if (!Mutate(() => _items.Add(item), () => Store!.InsertItem(item)))
        {
            return false;
        }

        created = item;
        return true;
    }

    bool Mutate(Action mutate, Action persist)
    {
        var categories = _categories.ToList();
        var items = _items.ToList();
        mutate();
        if (Store is null)
        {
            return true;
        }

        try
        {
            persist();
            return true;
        }
        catch (Exception exception)
        {
            PersistenceLog.Error(exception);
            _categories.Clear();
            _categories.AddRange(categories);
            _items.Clear();
            _items.AddRange(items);
            return false;
        }
    }

    int NextRootOrder(DateOnly day)
    {
        var orders = _items.Where(item => item.ParentId is null && item.ScheduledDate == day).Select(item => item.SortOrder);
        return orders.DefaultIfEmpty(-1).Max() + 1;
    }

    int NextChildOrder(Guid parentId)
    {
        var orders = _items.Where(item => item.ParentId == parentId).Select(item => item.SortOrder);
        return orders.DefaultIfEmpty(-1).Max() + 1;
    }

    static readonly string[] Palette = ["#4C6A82", "#8A7355", "#6E7F62", "#7A6578"];
}
