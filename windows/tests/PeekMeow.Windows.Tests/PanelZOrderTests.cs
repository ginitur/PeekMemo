using PeekMeow.Core.Interaction;
using Xunit;

namespace PeekMeow.Windows.Tests;

public class PanelZOrderTests
{
    [Fact]
    public void OpenCategoryWindowKeepsThePanelFromRaisingItself()
    {
        Assert.True(PanelZOrder.PreserveOrder(categoryWindowOpen: true));
        Assert.False(PanelZOrder.PreserveOrder(categoryWindowOpen: false));
        Assert.NotEqual(0u, ActivationStyle.NoZOrder);
    }
}
