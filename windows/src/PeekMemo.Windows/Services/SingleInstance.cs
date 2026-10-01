using System.Threading;

namespace PeekMemo.Windows.Services;

/// One edge panel per user session. A second process asks the first to show, then exits.
internal sealed class SingleInstance : IDisposable
{
    readonly Mutex _mutex;
    readonly EventWaitHandle _show;
    readonly bool _isFirst;
    readonly object _gate = new();
    RegisteredWaitHandle? _wait;
    bool _pending;
    Action? _onShow;

    public SingleInstance()
    {
        _mutex = new Mutex(true, @"Local\PeekMemo.SingleInstance", out _isFirst);
        _show = new EventWaitHandle(false, EventResetMode.AutoReset, @"Local\PeekMemo.Show");
        if (_isFirst)
        {
            _wait = ThreadPool.RegisterWaitForSingleObject(_show, OnShow, null, Timeout.Infinite, false);
        }
    }

    public bool IsFirst => _isFirst;

    public void SignalShow() => _show.Set();

    public void WhenShowRequested(Action handler)
    {
        bool fire;
        lock (_gate)
        {
            _onShow += handler;
            fire = _pending;
            _pending = false;
        }

        if (fire)
        {
            handler();
        }
    }

    void OnShow(object? state, bool timedOut)
    {
        if (timedOut)
        {
            return;
        }

        Action? handler;
        lock (_gate)
        {
            handler = _onShow;
            if (handler is null)
            {
                _pending = true;
            }
        }

        handler?.Invoke();
    }

    public void Dispose()
    {
        _wait?.Unregister(null);
        _show.Dispose();
        if (_isFirst)
        {
            try
            {
                _mutex.ReleaseMutex();
            }
            catch (ApplicationException)
            {
            }
        }

        _mutex.Dispose();
    }
}
