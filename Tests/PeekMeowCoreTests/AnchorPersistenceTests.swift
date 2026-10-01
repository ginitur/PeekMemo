import CoreGraphics
import PeekMeowCore

enum AnchorPersistenceTests {
    static let stack: CGFloat = 56
    static let panel = CGSize(width: 260, height: 228)

    static func run() throws {
        try expandDoesNotChangeOffset(.right, offset: 400)
        try expandDoesNotChangeOffset(.left, offset: 400)
        try expandDoesNotChangeOffset(.top, offset: 600)
        try expandDoesNotChangeOffset(.bottom, offset: 600)
        try rightCenterKeepsMidY()
        try leftCenterKeepsMidY()
        try topCenterKeepsMidX()
        try bottomCenterKeepsMidX()
    }

    static func expandDoesNotChangeOffset(_ edge: ScreenEdge, offset: CGFloat) throws {
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
        try expectEqual(layout.offset, collapsed.offset)
        try expectEqual(collapsed.stored.offset, layout.offset)
        let again = EdgeGeometry.collapsedPlacement(
            screen: screen, edge: edge, offset: layout.offset, stackLength: stack
        )
        try expectEqual(again.offset, collapsed.offset)
        try expectEqual(again.frame, collapsed.frame)
    }

    static func rightCenterKeepsMidY() throws {
        let collapsed = EdgeGeometry.collapsedPlacement(
            screen: Fixtures.external, edge: .right, offset: 500, stackLength: stack
        )
        let layout = ExpansionGeometry.layout(
            anchor: EdgeAnchor.from(collapsed.stored),
            screen: Fixtures.external,
            panelSize: panel,
            stackLength: stack
        )
        try expect(!layout.wasClamped)
        try expectEqual(layout.panelFrame.midY, collapsed.frame.midY)
        try expectEqual(layout.anchorPoint.y, collapsed.frame.midY)
        try expectEqual(layout.handleAttachmentPoint.y, collapsed.frame.midY)
        try expectEqual(layout.panelFrame.maxX, collapsed.frame.maxX)
    }

    static func leftCenterKeepsMidY() throws {
        let collapsed = EdgeGeometry.collapsedPlacement(
            screen: Fixtures.external, edge: .left, offset: 500, stackLength: stack
        )
        let layout = ExpansionGeometry.layout(
            anchor: EdgeAnchor.from(collapsed.stored),
            screen: Fixtures.external,
            panelSize: panel,
            stackLength: stack
        )
        try expectEqual(layout.panelFrame.midY, collapsed.frame.midY)
        try expectEqual(layout.panelFrame.minX, collapsed.frame.minX)
    }

    static func topCenterKeepsMidX() throws {
        let collapsed = EdgeGeometry.collapsedPlacement(
            screen: Fixtures.external, edge: .top, offset: 800, stackLength: stack
        )
        let layout = ExpansionGeometry.layout(
            anchor: EdgeAnchor.from(collapsed.stored),
            screen: Fixtures.external,
            panelSize: panel,
            stackLength: stack
        )
        try expectEqual(layout.panelFrame.midX, collapsed.frame.midX)
        try expectEqual(layout.panelFrame.maxY, collapsed.frame.maxY)
    }

    static func bottomCenterKeepsMidX() throws {
        let collapsed = EdgeGeometry.collapsedPlacement(
            screen: Fixtures.external, edge: .bottom, offset: 800, stackLength: stack
        )
        let layout = ExpansionGeometry.layout(
            anchor: EdgeAnchor.from(collapsed.stored),
            screen: Fixtures.external,
            panelSize: panel,
            stackLength: stack
        )
        try expectEqual(layout.panelFrame.midX, collapsed.frame.midX)
        try expectEqual(layout.panelFrame.minY, collapsed.frame.minY)
    }
}
