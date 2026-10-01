using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Windows.Media;
using PeekMemo.Core.Daily;
using PeekMemo.Core.Interaction;
using PeekMemo.Core.Models;

namespace PeekMemo.Windows.ViewModels;

public sealed class DailyMemoViewModel : INotifyPropertyChanged
{
    PresentationMode _mode = PresentationMode.Peek;

    public DailyMemoViewModel(DailySession session)
    {
        Session = session;
        session.Changed += Refresh;
        ShiftEarlierCommand = new RelayCommand(() => session.ShiftDate(-1));
        ShiftLaterCommand = new RelayCommand(() => session.ShiftDate(1));
        SelectAllCommand = new RelayCommand(() => ChooseCategory(null));
        AddTaskCommand = new RelayCommand(StartAddTask);
        Refresh();
    }

    public DailySession Session { get; }

    public event PropertyChangedEventHandler? PropertyChanged;
    public event Action? EditorFocusRequested;
    public event Action? BlurSuspended;
    public event Action<PresentationMode>? ModeChanged;
    public event Action? InteractionReleased;
    public event Action? CloseCategoryMenu;

    public RelayCommand ShiftEarlierCommand { get; }
    public RelayCommand ShiftLaterCommand { get; }
    public RelayCommand SelectAllCommand { get; }
    public RelayCommand AddTaskCommand { get; }

    public string DateLabel => Session.Board.DateLabel;
    public string? ProgressText => Session.Board.DayProgress.Text;
    public string FilterLabel => Session.Board.FilterLabel;
    public string PastHeading => $"未完成 · {Session.Board.PastUnfinishedItems.Count}";
    public bool ShowPast => Session.Board.PastUnfinishedItems.Count > 0;
    public bool ShowDayDivider => ShowPast && DailyRows.Count > 0;
    public bool IsAddingRoot => Session.Editing.Kind is EditorKind.NewTask or EditorKind.NewNote;
    public bool IsEditingCategory => Session.Editing.Kind is EditorKind.NewCategory or EditorKind.RenameCategory;
    public string CategoryEditorName =>
        Session.Editing.Kind == EditorKind.RenameCategory ? "Rename category" : "New category";
    public string AddEditorName => Session.Editing.Kind == EditorKind.NewNote ? "New note" : "New task";

    public string Draft
    {
        get => Session.Editing.Draft;
        set => Session.SetDraft(value);
    }

    public IReadOnlyList<MemoRowViewModel> PastRows { get; private set; } = [];
    public IReadOnlyList<MemoRowViewModel> DailyRows { get; private set; } = [];
    public IReadOnlyList<CategoryChoice> Categories { get; private set; } = [];

    public void ChooseCategory(Guid? id)
    {
        CloseCategoryMenu?.Invoke();
        Session.SelectCategory(id);
    }

    public void StartAddTask() => Session.BeginAddTask();

    public void StartAddNote() => Session.BeginAddNote();

    public void StartNewCategory() => Session.BeginNewCategory();

    public void StartRenameCategory(Guid id) => Session.BeginRenameCategory(id);

    public void OpenDatePicker() => Session.OpenDatePicker();

    public void NotifyDatePopupClosed(DateTimeOffset now)
    {
        if (!Session.DatePickerHoldsInteractive)
        {
            return;
        }

        Session.CloseDatePicker(now);
        InteractionReleased?.Invoke();
    }

    public void SelectDate(DateOnly date) => Session.SelectDate(date);

    public void BeginSurfaceHold() => Session.BeginSurfaceHold();

    public void EndSurfaceHold(DateTimeOffset now)
    {
        Session.EndSurfaceHold(now);
        InteractionReleased?.Invoke();
    }

    public void SubmitKey(bool enter, bool control, bool escape)
    {
        if (!Session.Editing.IsOpen)
        {
            return;
        }

        var stay = Session.SubmitKey(enter, control, escape, DateTimeOffset.Now);
        if (!stay)
        {
            InteractionReleased?.Invoke();
        }
    }

    public void CommitBlur(DateTimeOffset now)
    {
        if (!Session.Editing.IsOpen)
        {
            return;
        }

        var stay = Session.SubmitBlur(now);
        if (!stay)
        {
            InteractionReleased?.Invoke();
        }
    }

    internal void Toggle(Guid id) => Session.ToggleCompleted(id, DateTimeOffset.Now);

    internal void Edit(Guid id) => Session.BeginTitle(id);

    internal void AddSubtask(Guid id) => Session.BeginAddSubtask(id);

    internal void Delete(Guid id)
    {
        var wasOpen = Session.Editing.IsOpen;
        Session.Delete(id, DateTimeOffset.Now);
        if (wasOpen && !Session.Editing.IsOpen)
        {
            InteractionReleased?.Invoke();
        }
    }

    void Refresh()
    {
        BlurSuspended?.Invoke();
        PastRows = Session.Board.PastUnfinishedItems.Select(item => MakeRow(item, subtask: false)).ToList();
        DailyRows = Session.Board.DailyItems.Select(item => MakeRow(item, subtask: false)).ToList();
        Categories = Session.Board.ActiveCategories
            .Select(category => new CategoryChoice(this, category))
            .ToList();

        Raise(nameof(DateLabel));
        Raise(nameof(ProgressText));
        Raise(nameof(FilterLabel));
        Raise(nameof(PastHeading));
        Raise(nameof(ShowPast));
        Raise(nameof(ShowDayDivider));
        Raise(nameof(IsAddingRoot));
        Raise(nameof(IsEditingCategory));
        Raise(nameof(CategoryEditorName));
        Raise(nameof(AddEditorName));
        Raise(nameof(Draft));
        Raise(nameof(PastRows));
        Raise(nameof(DailyRows));
        Raise(nameof(Categories));

        var mode = Session.Interaction.Mode;
        var modeChanged = mode != _mode;
        _mode = mode;
        if (modeChanged)
        {
            ModeChanged?.Invoke(mode);
        }

        if (Session.Editing.IsOpen)
        {
            EditorFocusRequested?.Invoke();
        }
    }

    MemoRowViewModel MakeRow(MemoItem item, bool subtask)
    {
        IReadOnlyList<MemoRowViewModel> children = subtask
            ? []
            : TaskHierarchy.Children(Session.Board.Items, item.Id)
                .Select(child => MakeRow(child, subtask: true))
                .ToList();
        return new MemoRowViewModel(this, item, children, subtask);
    }

    void Raise(string name) => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
}

public sealed class CategoryChoice
{
    public CategoryChoice(DailyMemoViewModel owner, Category category)
    {
        Id = category.Id;
        Name = category.Name;
        SelectCommand = new RelayCommand(() => owner.ChooseCategory(category.Id));
    }

    public Guid Id { get; }
    public string Name { get; }
    public RelayCommand SelectCommand { get; }
}

public sealed class MemoRowViewModel
{
    readonly DailyMemoViewModel _owner;

    public MemoRowViewModel(
        DailyMemoViewModel owner,
        MemoItem item,
        IReadOnlyList<MemoRowViewModel> children,
        bool subtask)
    {
        _owner = owner;
        Id = item.Id;
        Title = item.Title;
        IsTask = item.Type == MemoItemType.Task;
        IsCompleted = item.IsCompleted;
        CategoryLabel = subtask ? null : owner.Session.Board.CategoryLabel(item);
        CategoryBrush = subtask ? null : BrushFrom(owner.Session.Board.CategoryColor(item));
        CanAddSubtask = !subtask && TaskHierarchy.CanAddSubtask(item);
        IsEditingTitle = owner.Session.Editing.Kind == EditorKind.Title && owner.Session.Editing.SubjectId == item.Id;
        IsEditingSubtask = owner.Session.Editing.Kind == EditorKind.NewSubtask && owner.Session.Editing.SubjectId == item.Id;
        Children = children;
        TitleSize = subtask ? 13 : 14;
        CompleteName = IsCompleted ? $"Mark {Title} incomplete" : $"Mark {Title} complete";
        RowOpacity = IsTask && IsCompleted ? 0.55 : 1;
        EditCommand = new RelayCommand(() => owner.Edit(item.Id));
        DeleteCommand = new RelayCommand(() => owner.Delete(item.Id));
        AddSubtaskCommand = new RelayCommand(() => owner.AddSubtask(item.Id));
    }

    public Guid Id { get; }
    public string Title { get; }
    public bool IsTask { get; }
    public bool IsNote => !IsTask;
    public bool IsCompleted { get; }
    public string? CategoryLabel { get; }
    public Brush? CategoryBrush { get; }
    public bool HasCategory => !string.IsNullOrWhiteSpace(CategoryLabel);
    public bool CanAddSubtask { get; }
    public bool IsEditingTitle { get; }
    public bool IsEditingSubtask { get; }
    public IReadOnlyList<MemoRowViewModel> Children { get; }
    public double TitleSize { get; }
    public string CompleteName { get; }
    public double RowOpacity { get; }
    public RelayCommand EditCommand { get; }
    public RelayCommand DeleteCommand { get; }
    public RelayCommand AddSubtaskCommand { get; }

    public string Draft
    {
        get => _owner.Draft;
        set => _owner.Draft = value;
    }

    static Brush? BrushFrom(string? hex)
    {
        if (string.IsNullOrWhiteSpace(hex))
        {
            return null;
        }

        try
        {
            if (ColorConverter.ConvertFromString(hex) is not Color color)
            {
                return null;
            }

            var brush = new SolidColorBrush(color);
            brush.Freeze();
            return brush;
        }
        catch (FormatException)
        {
            return null;
        }
        catch (NotSupportedException)
        {
            return null;
        }
        catch (InvalidOperationException)
        {
            return null;
        }
    }
}
