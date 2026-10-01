using PeekMemo.Core.Layout;
using Xunit;

namespace PeekMemo.Windows.Tests;

public class AtmosphereMarkTests
{
    [Fact]
    public void NormalDarkPanelKeepsTheMarkInTheQuietRange()
    {
        var layout = AtmosphereMark.Place(340, 460, lightBackground: false);
        var fraction = layout.Width / 340;
        Assert.InRange(fraction, AtmosphereMark.MinimumWidthFraction, AtmosphereMark.MaximumWidthFraction);
        Assert.Equal(AtmosphereMark.DarkOpacity, layout.Opacity);
        Assert.InRange(layout.Bleed, 0.01, layout.Width);
    }

    [Fact]
    public void WiderPanelUsesTheUpperSizeAndLightBackgroundIsQuieter()
    {
        var wide = AtmosphereMark.Place(480, 640, lightBackground: false);
        var light = AtmosphereMark.Place(340, 460, lightBackground: true);
        var dark = AtmosphereMark.Place(340, 460, lightBackground: false);
        Assert.Equal(AtmosphereMark.MaximumWidthFraction, wide.Width / 480, 3);
        Assert.True(wide.Width > dark.Width);
        Assert.Equal(dark.Width, light.Width);
        Assert.Equal(AtmosphereMark.LightOpacity, light.Opacity);
    }

    [Fact]
    public void NarrowShortAndEmptyPanelsRecede()
    {
        var normal = AtmosphereMark.Place(340, 460, lightBackground: false);
        var narrow = AtmosphereMark.Place(240, 460, lightBackground: false);
        var shortPanel = AtmosphereMark.Place(340, 300, lightBackground: false);
        var cramped = AtmosphereMark.Place(180, 200, lightBackground: true);
        var hidden = AtmosphereMark.Place(0, 460, lightBackground: false);

        Assert.True(narrow.Width / 240 < AtmosphereMark.MinimumWidthFraction);
        Assert.True(shortPanel.Width < normal.Width);
        Assert.True(shortPanel.Opacity < normal.Opacity);
        Assert.True(cramped.Opacity < 0.05);
        Assert.True(cramped.Width < 40);
        Assert.Equal(0, hidden.Width);
        Assert.Equal(0, hidden.Opacity);
    }
}
