using PeekMeow.Core.Hover;

namespace PeekMeow.Core.Interaction;

public enum PresentationMode
{
    Peek,
    Interactive
}

public enum InteractionActivity
{
    Idle,
    Dragging,
    Resizing
}

/// Drag, resize, menus, and edits hold the hover engine so a leave cannot collapse the window mid-gesture.
/// Interactive mode is an explicit edit or the date picker. Hover never enters it, and it is not a pin.
public sealed class PanelInteraction
{
    public HoverEngine Hover { get; } = new();
    public InteractionActivity Activity { get; private set; } = InteractionActivity.Idle;
    public PresentationMode Mode { get; private set; } = PresentationMode.Peek;
    public bool IsPinned => Hover.Phase == HoverPhase.Pinned;
    public int InteractionHoldCount => Hover.InteractionHoldCount;

    int _interactiveDepth;

    public void BeginDrag()
    {
        if (Activity != InteractionActivity.Idle)
        {
            return;
        }

        Activity = InteractionActivity.Dragging;
        Hover.BeginInteraction();
    }

    public void EndDrag(DateTimeOffset now)
    {
        if (Activity != InteractionActivity.Dragging)
        {
            return;
        }

        Activity = InteractionActivity.Idle;
        Hover.EndInteraction(now);
    }

    public void BeginResize()
    {
        if (Activity != InteractionActivity.Idle)
        {
            return;
        }

        Activity = InteractionActivity.Resizing;
        Hover.BeginInteraction();
    }

    public void EndResize(DateTimeOffset now)
    {
        if (Activity != InteractionActivity.Resizing)
        {
            return;
        }

        Activity = InteractionActivity.Idle;
        Hover.EndInteraction(now);
    }

    /// Typing, the date picker, or a new category. Holds collapse and allows activation.
    /// This is not a pin.
    public void BeginInteractive()
    {
        _interactiveDepth++;
        Mode = PresentationMode.Interactive;
        Hover.BeginInteraction();
    }

    public void EndInteractive(DateTimeOffset now)
    {
        if (_interactiveDepth == 0)
        {
            return;
        }

        _interactiveDepth--;
        if (_interactiveDepth == 0)
        {
            Mode = PresentationMode.Peek;
        }

        Hover.EndInteraction(now);
    }

    /// Menus and checkbox clicks. Holds collapse, stays in peek, and does not pin.
    public void BeginHold() => Hover.BeginInteraction();

    public void EndHold(DateTimeOffset now) => Hover.EndInteraction(now);

    public void EnterInteractive() => BeginInteractive();

    public void ReturnToPeek() => EndInteractive(DateTimeOffset.UtcNow);
}
