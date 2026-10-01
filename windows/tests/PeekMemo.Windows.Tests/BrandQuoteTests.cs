using PeekMemo.Core.Daily;
using Xunit;

namespace PeekMemo.Windows.Tests;

public class BrandQuoteTests
{
    [Fact]
    public void QuoteIsTheFrenchLineAndHidesWhenThePanelIsShort()
    {
        Assert.Equal(
            "Toutes les grandes personnes ont d’abord été des enfants. Mais peu d’entre elles s’en souviennent.",
            BrandQuote.Text);
        Assert.Contains("\u2019", BrandQuote.Text);
        Assert.False(BrandQuote.IsVisible(349));
        Assert.True(BrandQuote.IsVisible(350));
        Assert.True(BrandQuote.IsVisible(460));
    }
}
