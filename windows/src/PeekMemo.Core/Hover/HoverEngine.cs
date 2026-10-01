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

    DateTimeOffset? _openDue;
    DateTimeOffset? _closeDue;
    bool _inside;

    public DateTimeOffset? NextTransitionAt => Phase switch
    {
        HoverPhase.Collapsed => _openDue,
        HoverPhase.Expanded => _closeDue,
        _ => null
    };

    public void PointerEntered(DateTimeOffset now)
    {
        _inside = true;
        _closeDue = null;
        if (Phase is HoverPhase.Expanded or HoverPhase.Pinned)
        {
            return;
        }

        _openDue = now + OpenDelay;
    }

    public void PointerLeft(DateTimeOffset now)
    {
        _inside = false;
        _openDue = null;
        if (Phase != HoverPhase.Expanded)
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
