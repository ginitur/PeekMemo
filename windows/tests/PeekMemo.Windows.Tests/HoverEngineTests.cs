using PeekMemo.Core.Hover;
using Xunit;

namespace PeekMemo.Windows.Tests;

public class HoverEngineTests
{
    static readonly DateTimeOffset T0 = new(2026, 10, 1, 8, 0, 0, TimeSpan.Zero);

    [Fact]
    public void HoverOpensAfterTheDelayAndClosesAfterLeave()
    {
        var hover = new HoverEngine
        {
            OpenDelay = TimeSpan.FromMilliseconds(160),
            CloseDelay = TimeSpan.FromMilliseconds(350)
        };

        hover.PointerEntered(T0);
        Assert.False(hover.Tick(T0.AddMilliseconds(159)));
        Assert.Equal(HoverPhase.Collapsed, hover.Phase);
        Assert.True(hover.Tick(T0.AddMilliseconds(160)));
        Assert.Equal(HoverPhase.Expanded, hover.Phase);

        var left = T0.AddSeconds(1);
        hover.PointerLeft(left);
        Assert.False(hover.Tick(left.AddMilliseconds(349)));
        Assert.True(hover.Tick(left.AddMilliseconds(350)));
        Assert.Equal(HoverPhase.Collapsed, hover.Phase);
    }

    [Fact]
    public void PinnedIgnoresPointerLeave()
    {
        var hover = new HoverEngine();
        hover.ShowPinned();
        hover.PointerLeft(T0);
        Assert.False(hover.Tick(T0.AddSeconds(5)));
        Assert.Equal(HoverPhase.Pinned, hover.Phase);

        hover.TogglePin();
        Assert.Equal(HoverPhase.Collapsed, hover.Phase);
    }
}
