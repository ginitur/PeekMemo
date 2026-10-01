using PeekMemo.Core.Geometry;
using PeekMemo.Core.Layout;
using PeekMemo.Core.Models;
using Xunit;

namespace PeekMemo.Windows.Tests;

public class ResizeHandleRectTests
{
    [Theory]
    [InlineData(ScreenEdge.Right)]
    [InlineData(ScreenEdge.Left)]
    [InlineData(ScreenEdge.Bottom)]
    public void GripIsAtMost24AndSitsOnTheFreeCornerAwayFromTheDragHandle(ScreenEdge edge)
    {
        var work = new DipRect(0, 0, 1920, 1040);
        var offset = edge == ScreenEdge.Bottom ? work.Width / 2 : work.Height / 2;
        var layout = PlacementLayout.Create(new EdgeAnchor("m", edge, offset), work, 340, 460);
        var grip = PanelResizeGeometry.GripFrame(layout.ContentFrame, edge);
        var handle = DragHandleGeometry.Rect(layout, expanded: true);

        Assert.True(grip.Width <= 24);
        Assert.True(grip.Height <= 24);
        Assert.Equal(22d, grip.Width);
        Assert.Equal(22d, grip.Height);
        Assert.InRange(PanelResizeGeometry.VisualGripSize, 12, 14);
        Assert.True(PanelResizeGeometry.VisualGripSize < grip.Width);
        Assert.True(grip.Width * grip.Height < layout.ContentFrame.Width * layout.ContentFrame.Height / 4);
        Assert.False(Overlaps(grip, handle));
        Assert.False(grip.ContainsPoint(
            layout.ContentFrame.X + layout.ContentFrame.Width / 2,
            layout.ContentFrame.Y + layout.ContentFrame.Height / 2));

        switch (edge)
        {
            case ScreenEdge.Right:
                Assert.Equal(layout.ContentFrame.X + PanelResizeGeometry.GripInset, grip.X);
                Assert.Equal(layout.ContentFrame.Bottom - PanelResizeGeometry.GripInset, grip.Bottom);
                break;
            case ScreenEdge.Left:
                Assert.Equal(layout.ContentFrame.Right - PanelResizeGeometry.GripInset, grip.Right);
                Assert.Equal(layout.ContentFrame.Bottom - PanelResizeGeometry.GripInset, grip.Bottom);
                break;
            default:
                Assert.Equal(layout.ContentFrame.Right - PanelResizeGeometry.GripInset, grip.Right);
                Assert.Equal(layout.ContentFrame.Y + PanelResizeGeometry.GripInset, grip.Y);
                break;
        }
    }

    static bool Overlaps(DipRect a, DipRect b) =>
        a.X < b.Right && b.X < a.Right && a.Y < b.Bottom && b.Y < a.Bottom;
}
