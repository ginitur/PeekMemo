namespace PeekMeow.Core.Daily;

public enum EditorKind
{
    None,
    NewTask,
    NewNote,
    Title,
    NewSubtask,
    NewCategory,
    RenameCategory
}

public enum EditorAction
{
    None,
    SaveAndClose,
    SaveAndContinue,
    Cancel
}

/// One editor at a time. The text box exists only while <see cref="IsOpen"/> is true.
public sealed class EditingController
{
    public EditorKind Kind { get; private set; } = EditorKind.None;
    public Guid? SubjectId { get; private set; }
    public string Draft { get; set; } = "";
    public bool IsOpen => Kind != EditorKind.None;

    public void Begin(EditorKind kind, Guid? subjectId, string draft)
    {
        if (kind == EditorKind.None)
        {
            Close();
            return;
        }

        Kind = kind;
        SubjectId = subjectId;
        Draft = draft ?? "";
    }

    public EditorAction Key(bool enter, bool control, bool escape)
    {
        if (!IsOpen)
        {
            return EditorAction.None;
        }

        if (escape)
        {
            return EditorAction.Cancel;
        }

        if (!enter)
        {
            return EditorAction.None;
        }

        if (Kind == EditorKind.NewSubtask && !control)
        {
            return string.IsNullOrWhiteSpace(Draft) ? EditorAction.None : EditorAction.SaveAndContinue;
        }

        return EditorAction.SaveAndClose;
    }

    public EditorAction Blur()
    {
        if (!IsOpen)
        {
            return EditorAction.None;
        }

        return string.IsNullOrWhiteSpace(Draft) ? EditorAction.Cancel : EditorAction.SaveAndClose;
    }

    /// Returns true when the editor stays open (another blank subtask field).
    public bool Apply(MemoBoard board, EditorAction action)
    {
        if (!IsOpen || action == EditorAction.None)
        {
            return IsOpen;
        }

        if (action == EditorAction.Cancel)
        {
            Close();
            return false;
        }

        var text = Draft.Trim();
        if (text.Length == 0)
        {
            Close();
            return false;
        }

        var stay = action == EditorAction.SaveAndContinue && Kind == EditorKind.NewSubtask;
        var subject = SubjectId;
        switch (Kind)
        {
            case EditorKind.NewTask:
                board.TryAddTask(text, out _);
                break;
            case EditorKind.NewNote:
                board.TryAddNote(text, out _);
                break;
            case EditorKind.Title when subject is Guid id:
                board.TryRename(id, text);
                break;
            case EditorKind.NewSubtask when subject is Guid parentId:
                board.TryAddSubtask(parentId, text, out _);
                break;
            case EditorKind.NewCategory:
                board.TryAddCategory(text, out _);
                break;
            case EditorKind.RenameCategory when subject is Guid categoryId:
                board.TryRenameCategory(categoryId, text);
                break;
        }

        if (stay)
        {
            Draft = "";
            return true;
        }

        Close();
        return false;
    }

    public void Close()
    {
        Kind = EditorKind.None;
        SubjectId = null;
        Draft = "";
    }
}
