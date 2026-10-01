import CoreGraphics
import PeekMeowCore

enum CornerClampAnchorTests {
    static let stack: CGFloat = 56
    static let panel = CGSize(width: 260, height: 228)

    static func run() throws {
        try rightNearTopClampsPanelKeepsHandle()
        try rightNearBottomClampsPanelKeepsHandle()
        try leftNearTop()
        try leftNearBottom()
        try topNearLeft()
        try topNearRight()
        try bottomNearLeft()
        try bottomNearRight()
    }

    static func rightNearTopClampsPanelKeepsHandle() throws {
        try verticalCorner(edge: .right, offset: 30)
    }

    static func rightNearBottomClampsPanelKeepsHandle() throws {
        let span = Fixtures.external.visibleFrame.height
        try verticalCorner(edge: .right, offset: span - 30)
    }

    static func leftNearTop() throws {
        try verticalCorner(edge: .left, offset: 30)
    }

    static func leftNearBottom() throws {
        let span = Fixtures.external.visibleFrame.height
        try verticalCorner(edge: .left, offset: span - 30)
    }

    static func topNearLeft() throws {
        try horizontalCorner(edge: .top, offset: 30)
    }

    static func topNearRight() throws {
        let span = Fixtures.external.visibleFrame.width
        try horizontalCorner(edge: .top, offset: span - 30)
    }

    static func bottomNearLeft() throws {
        try horizontalCorner(edge: .bottom, offset: 30)
    }

    static func bottomNearRight() throws {
        let span = Fixtures.external.visibleFrame.width
        try horizontalCorner(edge: .bottom, offset: span - 30)
    }

    private static func verticalCorner(edge: ScreenEdge, offset: CGFloat) throws {
        let screen = Fixtures.external
        let collapsed = EdgeGeometry.collapsedPlacement(
            screen: screen, edge: edge, offset: offset, stackLength: stack
        )
        let layout = ExpansionGeometry.layout(
            anchor: EdgeAnchor.from(collapsed.stored),
            screen: screen,
            panelSize: panel,
            stackLength: stack
        )
        try expect(layout.wasClamped)
        try expectEqual(layout.offset, collapsed.offset)
        try expectEqual(layout.handleAttachmentPoint.y, collapsed.frame.midY)
        try expect(layout.panelFrame.minY >= screen.visibleFrame.minY - 0.5)
        try expect(layout.panelFrame.maxY <= screen.visibleFrame.maxY + 0.5)
        try expect(layout.panelFrame.minY <= layout.handleAttachmentPoint.y)
        try expect(layout.panelFrame.maxY >= layout.handleAttachmentPoint.y)
        let expectedHandleOffset = layout.panelFrame.maxY - collapsed.frame.midY
        try expect(abs(layout.handleOffsetInsidePanel - expectedHandleOffset) < 0.5)
    }

    private static func horizontalCorner(edge: ScreenEdge, offset: CGFloat) throws {
        let screen = Fixtures.external
        let collapsed = EdgeGeometry.collapsedPlacement(
            screen: screen, edge: edge, offset: offset, stackLength: stack
        )
        let layout = ExpansionGeometry.layout(
            anchor: EdgeAnchor.from(collapsed.stored),
            screen: screen,
            panelSize: panel,
            stackLength: stack
        )
        try expect(layout.wasClamped)
        try expectEqual(layout.offset, collapsed.offset)
        try expectEqual(layout.handleAttachmentPoint.x, collapsed.frame.midX)
        try expect(layout.panelFrame.minX >= screen.visibleFrame.minX - 0.5)
        try expect(layout.panelFrame.maxX <= screen.visibleFrame.maxX + 0.5)
        try expect(layout.panelFrame.minX <= layout.handleAttachmentPoint.x)
        try expect(layout.panelFrame.maxX >= layout.handleAttachmentPoint.x)
    }
}
