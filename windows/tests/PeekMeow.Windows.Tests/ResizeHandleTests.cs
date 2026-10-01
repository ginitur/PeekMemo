using PeekMeow.Core.Geometry;
using PeekMeow.Core.Models;
using Xunit;

namespace PeekMeow.Windows.Tests;

public class ResizeHandleTests
{
    static readonly DipRect Card = new(0, 0, 340, 460);

    [Fact]
    public void GripIsAtMost24By24OnEverySupportedEdge()
    {
        Assert.True(PanelResizeGeometry.GripSize <= PanelResizeGeometry.MaximumHitSize);
        Assert.True(PanelResizeGeometry.GripSize <= 24);
        Assert.True(PanelResizeGeometry.VisualGripSize < PanelResizeGeometry.GripSize);

        foreach (var edge in new[] { ScreenEdge.Right, ScreenEdge.Left, ScreenEdge.Bottom })
        {
            var grip = PanelResizeGeometry.GripFrame(Card, edge);
            Assert.True(grip.Width <= 24, edge.ToString());
            Assert.True(grip.Height <= 24, edge.ToString());
            Assert.Equal(22d, grip.Width);
            Assert.Equal(22d, grip.Height);
            Assert.False(grip.ContainsPoint(Card.Width / 2, Card.Height / 2));
        }
    }

    [Fact]
    public void GripSitsOnTheFreeCornerAndDoesNotCoverTheCard()
    {
        var right = PanelResizeGeometry.GripFrame(Card, ScreenEdge.Right);
        Assert.Equal(6d, right.X);
        Assert.Equal(Card.Bottom - 6, right.Bottom);

        var left = PanelResizeGeometry.GripFrame(Card, ScreenEdge.Left);
        Assert.Equal(Card.Right - 6, left.Right);
        Assert.Equal(Card.Bottom - 6, left.Bottom);

        var bottom = PanelResizeGeometry.GripFrame(Card, ScreenEdge.Bottom);
        Assert.Equal(Card.Right - 6, bottom.Right);
        Assert.Equal(6d, bottom.Y);

        Assert.False(PanelResizeGeometry.BeginsResize(170, 24, Card, ScreenEdge.Right));
        Assert.False(PanelResizeGeometry.BeginsResize(170, 230, Card, ScreenEdge.Right));
        Assert.True(PanelResizeGeometry.BeginsResize(10, 440, Card, ScreenEdge.Right));
    }
}
