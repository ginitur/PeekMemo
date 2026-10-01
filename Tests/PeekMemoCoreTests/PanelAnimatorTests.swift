import CoreGraphics
import PeekMemoCore

enum PanelAnimatorTests {
    static func run() throws {
        try rightExpandKeepsMaxX()
        try leftExpandKeepsMinX()
        try topExpandKeepsMaxY()
        try bottomExpandKeepsMinY()
        try interpolationEndpoints()
        try midpointIsBetween()
    }

    static func rightExpandKeepsMaxX() throws {
        let screen = Fixtures.external
        let collapsed = EdgeGeometry.collapsedPlacement(
            screen: screen, edge: .right, offset: 80, stackLength: 56
        )
        let expanded = EdgeGeometry.expandedFrame(
            collapsed: collapsed, screen: screen, panelSize: CGSize(width: 260, height: 228)
        )
        try expect(PanelAnimator.fixedEdgeHolds(from: collapsed.frame, to: expanded, edge: .right))
        try expectEqual(PanelAnimator.fixedEdge(for: collapsed), .right)
        try expectEqual(collapsed.frame.maxX, expanded.maxX)
    }

    static func leftExpandKeepsMinX() throws {
        let screen = Fixtures.external
        let collapsed = EdgeGeometry.collapsedPlacement(
            screen: screen, edge: .left, offset: 80, stackLength: 56
        )
        let expanded = EdgeGeometry.expandedFrame(
            collapsed: collapsed, screen: screen, panelSize: CGSize(width: 260, height: 228)
        )
        try expect(PanelAnimator.fixedEdgeHolds(from: collapsed.frame, to: expanded, edge: .left))
        try expectEqual(collapsed.frame.minX, expanded.minX)
    }

    static func topExpandKeepsMaxY() throws {
        let screen = Fixtures.external
        let collapsed = EdgeGeometry.collapsedPlacement(
            screen: screen, edge: .top, offset: 200, stackLength: 56
        )
        let expanded = EdgeGeometry.expandedFrame(
            collapsed: collapsed, screen: screen, panelSize: CGSize(width: 260, height: 228)
        )
        try expect(PanelAnimator.fixedEdgeHolds(from: collapsed.frame, to: expanded, edge: .top))
        try expectEqual(collapsed.frame.maxY, expanded.maxY)
    }

    static func bottomExpandKeepsMinY() throws {
        let screen = Fixtures.external
        let collapsed = EdgeGeometry.collapsedPlacement(
            screen: screen, edge: .bottom, offset: 200, stackLength: 56
        )
        let expanded = EdgeGeometry.expandedFrame(
            collapsed: collapsed, screen: screen, panelSize: CGSize(width: 260, height: 228)
        )
        try expect(PanelAnimator.fixedEdgeHolds(from: collapsed.frame, to: expanded, edge: .bottom))
        try expectEqual(collapsed.frame.minY, expanded.minY)
    }

    static func interpolationEndpoints() throws {
        let a = CGRect(x: 100, y: 10, width: 14, height: 56)
        let b = CGRect(x: 100, y: 10, width: 260, height: 228)
        try expectEqual(PanelAnimator.interpolated(from: a, to: b, progress: 0), a)
        try expectEqual(PanelAnimator.interpolated(from: a, to: b, progress: 1), b)
        try expectEqual(PanelAnimator.interpolated(from: a, to: b, progress: -1), a)
        try expectEqual(PanelAnimator.interpolated(from: a, to: b, progress: 2), b)
    }

    static func midpointIsBetween() throws {
        let a = CGRect(x: 0, y: 0, width: 10, height: 10)
        let b = CGRect(x: 10, y: 20, width: 30, height: 50)
        let mid = PanelAnimator.interpolated(from: a, to: b, progress: 0.5)
        try expectEqual(mid.origin.x, 5)
        try expectEqual(mid.origin.y, 10)
        try expectEqual(mid.width, 20)
        try expectEqual(mid.height, 30)
    }
}
