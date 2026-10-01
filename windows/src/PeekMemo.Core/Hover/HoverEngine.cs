namespace PeekMemo.Core.Hover;

public enum HoverPhase
{
    Collapsed,
    Expanded,
    Pinned
}

/// Open and close delays. The caller feeds pointer events. This type does not read the mouse.
public sealed class HoverEngine
{
    public HoverPhase Phase { get; private set; } = HoverPhase.Collapsed;
    public TimeSpan OpenDelay { get; set; } = TimeSpan.FromMilliseconds(160);
    public TimeSpan CloseDelay { get; set; } = TimeSpan.FromMilliseconds(350);
    public bool InteractionHeld => _interactionHold > 0;
    public int InteractionHoldCount => _interactionHold;
    public int Generation { get; private set; }

    DateTimeOffset? _openDue;
    DateTimeOffset? _closeDue;
    bool _inside;
    int _interactionHold;

    public DateTimeOffset? NextTransitionAt => Phase switch
    {
        HoverPhase.Collapsed => _openDue,
        HoverPhase.Expanded => _closeDue,
        _ => null
    };

    public void BeginInteraction()
    {
        _interactionHold++;
        _openDue = null;
        _closeDue = null;
        Generation++;
    }

    public void EndInteraction(DateTimeOffset now)
    {
        if (_interactionHold == 0)
        {
            return;
        }

        _interactionHold--;
        Generation++;
        if (_interactionHold > 0)
        {
            return;
        }

        if (Phase == HoverPhase.Expanded && !_inside)
        {
            _closeDue = now + CloseDelay;
        }
        else if (Phase == HoverPhase.Collapsed && _inside)
        {
            _openDue = now + OpenDelay;
        }
    }

    public void PointerEntered(DateTimeOffset now)
    {
        _inside = true;
        _closeDue = null;
        Generation++;
        if (_interactionHold > 0 || Phase is HoverPhase.Expanded or HoverPhase.Pinned)
        {
            return;
        }

        _openDue = now + OpenDelay;
    }

    public void PointerLeft(DateTimeOffset now)
    {
        _inside = false;
        _openDue = null;
        Generation++;
        if (_interactionHold > 0 || Phase != HoverPhase.Expanded)
        {
            return;
        }

        _closeDue = now + CloseDelay;
    }

    public void TogglePin()
    {
        if (Phase == HoverPhase.Pinned)
        {
            Phase = _inside ? HoverPhase.Expanded : HoverPhase.Collapsed;
            _openDue = null;
            _closeDue = null;
            return;
        }

        Phase = HoverPhase.Pinned;
        _openDue = null;
        _closeDue = null;
    }

    public void ShowPinned()
    {
        Phase = HoverPhase.Pinned;
        _openDue = null;
        _closeDue = null;
    }

    public bool Tick(DateTimeOffset now)
    {
        if (_interactionHold > 0)
        {
            return false;
        }

        var before = Phase;
        if (Phase == HoverPhase.Collapsed && _openDue is DateTimeOffset open && now >= open)
        {
            Phase = HoverPhase.Expanded;
            _openDue = null;
        }

        if (Phase == HoverPhase.Expanded && _closeDue is DateTimeOffset close && now >= close)
        {
            Phase = HoverPhase.Collapsed;
            _closeDue = null;
        }

        return Phase != before;
    }
}
