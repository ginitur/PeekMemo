import CoreGraphics
import PeekMemoCore

enum EdgeGeometryTests {
    static let stack: CGFloat = 96

    static func run() throws {
        try rightEdgeSitsOnPhysicalOuterEdge()
        try leftEdgeSitsOnPhysicalOuterEdge()
        try topEdgeSitsBelowMenuBar()
        try bottomEdgeSitsOnPhysicalBottom()
        try offsetClampsToVisibleSpan()
        try rightDockUsesVisibleFrameSoTabStaysHittable()
        try expansionDirectionFollowsEdge()
        try nearestEdgePicksClosestSide()
        try dragSnapsInsideMagnetRange()
        try dragFloatsOutsideMagnetRange()
        try mouseUpAlwaysSnaps()
        try expandedPanelOpensInwardFromRight()
        try topOfTheScreenDoesNotSnapToTop()
        try storedTopRestoresToRight()
    }

    static func rightEdgeSitsOnPhysicalOuterEdge() throws {
        let placement = EdgeGeometry.collapsedPlacement(
            screen: Fixtures.external,
            edge: .right,
            offset: 120,
            stackLength: stack
        )
        try expectEqual(placement.edge, .right)
        try expect(placement.isSnapped)
        try expectEqual(placement.frame.maxX, Fixtures.external.frame.maxX)
        try expectEqual(placement.frame.width, LayoutMetrics.hoverHitThickness)
        try expectEqual(placement.frame.height, stack)
        try expectEqual(placement.frame.midY, Fixtures.external.visibleFrame.maxY - 120)
    }

    static func leftEdgeSitsOnPhysicalOuterEdge() throws {
        let placement = EdgeGeometry.collapsedPlacement(
            screen: Fixtures.external,
            edge: .left,
            offset: 40,
            stackLength: stack
        )
        try expectEqual(placement.frame.minX, Fixtures.external.frame.minX)
        try expectEqual(placement.frame.width, LayoutMetrics.hoverHitThickness)
    }

    static func topEdgeSitsBelowMenuBar() throws {
        let placement = EdgeGeometry.collapsedPlacement(
            screen: Fixtures.external,
            edge: .top,
            offset: 200,
            stackLength: stack
        )
        try expectEqual(placement.frame.maxY, Fixtures.external.visibleFrame.maxY)
        try expectEqual(placement.frame.height, LayoutMetrics.hoverHitThickness)
        try expectEqual(placement.frame.midX, Fixtures.external.visibleFrame.minX + 200)
    }

    static func bottomEdgeSitsOnPhysicalBottom() throws {
        let placement = EdgeGeometry.collapsedPlacement(
            screen: Fixtures.external,
            edge: .bottom,
            offset: 10,
            stackLength: stack
        )
        try expectEqual(placement.frame.minY, Fixtures.external.frame.minY)
    }

    static func offsetClampsToVisibleSpan() throws {
        let huge = EdgeGeometry.clampOffset(
            10_000,
            edge: .right,
            screen: Fixtures.external,
            stackLength: stack
        )
        try expectEqual(huge, Fixtures.external.visibleFrame.height - stack / 2)

        let negative = EdgeGeometry.clampOffset(
            -40,
            edge: .top,
            screen: Fixtures.external,
            stackLength: stack
        )
        try expectEqual(negative, stack / 2)
    }

    static func rightDockUsesVisibleFrameSoTabStaysHittable() throws {
        let placement = EdgeGeometry.collapsedPlacement(
            screen: Fixtures.dockRight,
            edge: .right,
            offset: 80,
            stackLength: stack
        )
        try expectEqual(placement.frame.maxX, Fixtures.dockRight.visibleFrame.maxX)
    }

    static func expansionDirectionFollowsEdge() throws {
        try expectEqual(ScreenEdge.right.expansion, .left)
        try expectEqual(ScreenEdge.left.expansion, .right)
        try expectEqual(ScreenEdge.top.expansion, .down)
        try expectEqual(ScreenEdge.bottom.expansion, .up)
    }

    static func nearestEdgePicksClosestSide() throws {
        let screen = Fixtures.external
        try expectEqual(EdgeGeometry.nearestEdge(to: CGPoint(x: 1910, y: 500), on: screen).0, .right)
        try expectEqual(EdgeGeometry.nearestEdge(to: CGPoint(x: 900, y: 1075), on: screen).0, .top)
        try expectEqual(EdgeGeometry.nearestEdge(to: CGPoint(x: 4, y: 400), on: screen).0, .left)
        try expectEqual(EdgeGeometry.nearestEdge(to: CGPoint(x: 400, y: 3), on: screen).0, .bottom)
    }

    static func dragSnapsInsideMagnetRange() throws {
        let pointer = CGPoint(x: Fixtures.external.frame.maxX - 10, y: 600)
        let placement = EdgeGeometry.draggingPlacement(
            pointer: pointer,
            screen: Fixtures.external,
            stackLength: stack,
            grabSize: CGSize(width: 40, height: stack)
        )
        try expect(placement.isSnapped)
        try expectEqual(placement.edge, .right)
        try expectEqual(placement.frame.maxX, Fixtures.external.frame.maxX)
    }

    static func dragFloatsOutsideMagnetRange() throws {
        let pointer = CGPoint(x: 960, y: 540)
        let placement = EdgeGeometry.draggingPlacement(
            pointer: pointer,
            screen: Fixtures.external,
            stackLength: stack,
            grabSize: CGSize(width: 40, height: stack)
        )
        try expect(!placement.isSnapped)
        try expectEqual(placement.frame.midX, pointer.x)
        try expectEqual(placement.frame.midY, pointer.y)
    }

    static func mouseUpAlwaysSnaps() throws {
        let pointer = CGPoint(x: 960, y: 540)
        let placement = EdgeGeometry.committedPlacement(
            pointer: pointer,
            screen: Fixtures.external,
            stackLength: stack
        )
        try expect(placement.isSnapped)
    }

    static func expandedPanelOpensInwardFromRight() throws {
        let collapsed = EdgeGeometry.collapsedPlacement(
            screen: Fixtures.external,
            edge: .right,
            offset: 500,
            stackLength: stack
        )
        let expanded = EdgeGeometry.expandedFrame(
            collapsed: collapsed,
            screen: Fixtures.external,
            panelSize: CGSize(width: 280, height: 360)
        )
        try expectEqual(expanded.maxX, collapsed.frame.maxX)
        try expectEqual(expanded.midY, collapsed.frame.midY)
        try expectEqual(expanded.width, 280)
        try expectEqual(expanded.height, 360)
    }

    static func topOfTheScreenDoesNotSnapToTop() throws {
        let screen = Fixtures.external
        let pointer = CGPoint(x: screen.frame.midX, y: screen.frame.maxY - 4)
        let committed = EdgeGeometry.committedPlacement(
            pointer: pointer,
            screen: screen,
            stackLength: stack
        )
        try expect(committed.edge != .top)
        try expect(PlacementPolicy.isSupported(committed.edge))
    }

    static func storedTopRestoresToRight() throws {
        let stored = DisplayPlacement(
            displayIdentifier: Fixtures.external.identifier,
            edge: .top,
            offset: 200
        )
        let placement = EdgeGeometry.placement(
            from: stored,
            screen: Fixtures.external,
            stackLength: stack
        )
        try expectEqual(placement.edge, .right)
    }
}
