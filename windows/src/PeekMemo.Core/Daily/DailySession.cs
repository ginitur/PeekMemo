using PeekMemo.Core.Interaction;
using PeekMemo.Core.Models;

namespace PeekMemo.Core.Daily;

/// In-memory date, category, and editor flow for the panel.
/// Interactive mode is typing or the date picker. It is not a pin.
/// Menus and checkboxes only hold auto-collapse.
public sealed class DailySession
{
    public MemoBoard Board { get; }
    public EditingController Editing { get; } = new();
    public PanelInteraction Interaction { get; }

    public DailySession(MemoBoard board, PanelInteraction interaction)
    {
        Board = board;
        Interaction = interaction;
    }

    public bool EditorHoldsInteractive { get; private set; }
    public bool DatePickerHoldsInteractive { get; private set; }

    public event Action? Changed;

    public void ShiftDate(int days)
    {
        Board.ShiftDate(days);
        Changed?.Invoke();
    }

    public void SelectDate(DateOnly date)
    {
        Board.SelectDate(date);
        Changed?.Invoke();
    }

    public void SelectCategory(Guid? categoryId)
    {
        Board.SelectCategory(categoryId);
        Changed?.Invoke();
    }

    public void BeginAddTask() => BeginEditor(EditorKind.NewTask, null, "");

    public void BeginAddNote() => BeginEditor(EditorKind.NewNote, null, "");

    public void BeginAddSubtask(Guid parentId) => BeginEditor(EditorKind.NewSubtask, parentId, "");

    public void BeginTitle(Guid id)
    {
        var item = Board.Items.FirstOrDefault(candidate => candidate.Id == id);
        if (item is null)
        {
            return;
        }

        BeginEditor(EditorKind.Title, id, item.Title);
    }

    public void BeginNewCategory() => BeginEditor(EditorKind.NewCategory, null, "");

    public void BeginRenameCategory(Guid id)
    {
        var category = Board.ActiveCategories.FirstOrDefault(candidate => candidate.Id == id);
        if (category is null)
        {
            return;
        }

        BeginEditor(EditorKind.RenameCategory, id, category.Name);
    }

    public void SetDraft(string? draft) => Editing.Draft = draft ?? "";

    /// True when the editor stays open for another subtask.
    public bool SubmitKey(bool enter, bool control, bool escape, DateTimeOffset now)
    {
        if (!Editing.IsOpen)
        {
            return false;
        }

        return Commit(Editing.Key(enter, control, escape), now);
    }

    public bool SubmitBlur(DateTimeOffset now)
    {
        if (!Editing.IsOpen)
        {
            return false;
        }

        return Commit(Editing.Blur(), now);
    }

    public void OpenDatePicker()
    {
        if (DatePickerHoldsInteractive)
        {
            return;
        }

        DatePickerHoldsInteractive = true;
        Interaction.BeginInteractive();
        Changed?.Invoke();
    }

    public void CloseDatePicker(DateTimeOffset now)
    {
        if (!DatePickerHoldsInteractive)
        {
            return;
        }

        DatePickerHoldsInteractive = false;
        Interaction.EndInteractive(now);
        Changed?.Invoke();
    }

    public void BeginSurfaceHold() => Interaction.BeginHold();

    public void EndSurfaceHold(DateTimeOffset now) => Interaction.EndHold(now);

    public void ToggleCompleted(Guid id, DateTimeOffset now)
    {
        var item = Board.Items.FirstOrDefault(candidate => candidate.Id == id);
        if (item is null || item.Type != MemoItemType.Task)
        {
            return;
        }

        Board.SetCompleted(id, !item.IsCompleted, now);
        Changed?.Invoke();
    }

    public void Delete(Guid id, DateTimeOffset now)
    {
        var closeEditor = EditorTouches(id);
        if (!Board.Delete(id))
        {
            return;
        }

        if (closeEditor)
        {
            Editing.Close();
            ReleaseEditor(now);
        }

        Changed?.Invoke();
    }

    void BeginEditor(EditorKind kind, Guid? subjectId, string draft)
    {
        Editing.Begin(kind, subjectId, draft);
        if (!EditorHoldsInteractive)
        {
            EditorHoldsInteractive = true;
            Interaction.BeginInteractive();
        }

        Changed?.Invoke();
    }

    bool Commit(EditorAction action, DateTimeOffset now)
    {
        if (action == EditorAction.None)
        {
            return Editing.IsOpen;
        }

        var stay = Editing.Apply(Board, action);
        if (!stay)
        {
            ReleaseEditor(now);
        }

        Changed?.Invoke();
        return stay;
    }

    void ReleaseEditor(DateTimeOffset now)
    {
        if (!EditorHoldsInteractive)
        {
            return;
        }

        EditorHoldsInteractive = false;
        Interaction.EndInteractive(now);
    }

    bool EditorTouches(Guid id)
    {
        if (!Editing.IsOpen)
        {
            return false;
        }

        if (Editing.SubjectId == id)
        {
            return true;
        }

        if (Editing.SubjectId is not Guid subject)
        {
            return false;
        }

        var subjectItem = Board.Items.FirstOrDefault(item => item.Id == subject);
        return subjectItem?.ParentId == id;
    }
}
