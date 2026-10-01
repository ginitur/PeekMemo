using PeekMemo.Core.Geometry;
using PeekMemo.Core.Models;
using Xunit;

namespace PeekMemo.Windows.Tests;

public class CornerClampTests
{
    static readonly DipRect Work = new(0, 0, 1920, 1040);

    [Theory]
    [InlineData(ScreenEdge.Right, 40)]
    [InlineData(ScreenEdge.Left, 40)]
    public void NearTheTopTheBodyClampsAndTheAnchorStays(ScreenEdge edge, double offset)
    {
        var layout = PlacementLayout.Create(new EdgeAnchor("m", edge, offset), Work, 340, 460);

        Assert.True(layout.WasClamped);
        Assert.Equal(offset, layout.Anchor.Offset);
        Assert.Equal(Work.Y, layout.ContentFrame.Y);
        Assert.Equal(Work.Y + offset, layout.HandleAttachmentPoint.Y);
        Assert.NotEqual(layout.ContentFrame.Y + layout.ContentFrame.Height / 2, layout.HandleAttachmentPoint.Y);
        Assert.True(layout.ContentFrame.Bottom <= Work.Bottom + 0.01);
    }

    [Theory]
    [InlineData(ScreenEdge.Right)]
    [InlineData(ScreenEdge.Left)]
    public void NearTheBottomTheBodyClampsAndTheAnchorStays(ScreenEdge edge)
    {
        var offset = Work.Height - 40;
        var layout = PlacementLayout.Create(new EdgeAnchor("m", edge, offset), Work, 340, 460);

        Assert.True(layout.WasClamped);
        Assert.Equal(offset, layout.Anchor.Offset);
        Assert.Equal(Work.Bottom, layout.ContentFrame.Bottom);
        Assert.Equal(Work.Y + offset, layout.HandleAttachmentPoint.Y);
        Assert.True(layout.HandleAttachmentPoint.Y < layout.ContentFrame.Bottom);
        Assert.True(layout.HandleAttachmentPoint.Y > layout.ContentFrame.Y);
    }

    [Fact]
    public void BottomNearTheLeftAndRightCornersClampsTheBodyOnly()
    {
        var left = PlacementLayout.Create(new EdgeAnchor("m", ScreenEdge.Bottom, 40), Work, 340, 460);
        Assert.True(left.WasClamped);
        Assert.Equal(40d, left.Anchor.Offset);
        Assert.Equal(Work.X, left.ContentFrame.X);
        Assert.Equal(Work.X + 40, left.HandleAttachmentPoint.X);
        Assert.Equal(Work.Bottom, left.ExpandedFrame.Bottom);

        var rightOffset = Work.Width - 40;
        var right = PlacementLayout.Create(new EdgeAnchor("m", ScreenEdge.Bottom, rightOffset), Work, 340, 460);
        Assert.True(right.WasClamped);
        Assert.Equal(rightOffset, right.Anchor.Offset);
        Assert.Equal(Work.Right, right.ContentFrame.Right);
        Assert.Equal(Work.X + rightOffset, right.HandleAttachmentPoint.X);
        Assert.Equal(Work.Bottom, right.ExpandedFrame.Bottom);
        Assert.NotEqual(right.ContentFrame.X + right.ContentFrame.Width / 2, right.HandleAttachmentPoint.X);
    }
}
