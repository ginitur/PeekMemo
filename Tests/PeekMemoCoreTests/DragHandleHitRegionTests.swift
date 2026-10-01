import CoreGraphics
import PeekMemoCore

enum DragHandleHitRegionTests {
    static func run() throws {
        try rightHandleOnOuterEdge()
        try topHandleSitsAtTop()
    }

    static func rightHandleOnOuterEdge() throws {
        let bounds = CGRect(x: 0, y: 0, width: 280, height: 320)
        let rect = DragHandleGeometry.rect(
            in: bounds,
            edge: .right,
            handleOffsetInsidePanel: 160,
            stackLength: 56
        )
        try expectEqual(rect.maxX, bounds.maxX)
        try expectEqual(rect.width, LayoutMetrics.hoverHitThickness)
        try expect(rect.height == 56)
    }

    static func topHandleSitsAtTop() throws {
        let bounds = CGRect(x: 0, y: 0, width: 280, height: 320)
        let rect = DragHandleGeometry.rect(
            in: bounds,
            edge: .top,
            handleOffsetInsidePanel: 140,
            stackLength: 56
        )
        try expectEqual(rect.maxY, bounds.height)
    }
}
