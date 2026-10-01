using PeekMemo.Core.Hover;

namespace PeekMemo.Core.Interaction;

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

/// Drag and resize hold the hover engine so a leave cannot collapse the window mid-gesture.
/// Interactive mode is reserved for a later explicit edit. Nothing in this type enters it on hover.
public sealed class PanelInteraction
{
    public HoverEngine Hover { get; } = new();
    public InteractionActivity Activity { get; private set; } = InteractionActivity.Idle;
    public PresentationMode Mode { get; private set; } = PresentationMode.Peek;

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

    public void EnterInteractive() => Mode = PresentationMode.Interactive;

    public void ReturnToPeek() => Mode = PresentationMode.Peek;
}
