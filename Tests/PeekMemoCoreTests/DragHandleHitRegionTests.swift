import CoreGraphics
import PeekMemoCore

enum DragHandleHitRegionTests {
    static func run() throws {
        try rightHandleOnOuterEdge()
        try topHandleAccountsForNotchOcclusion()
        try topHandleWithoutNotchSitsAtTop()
    }

    static func rightHandleOnOuterEdge() throws {
        let bounds = CGRect(x: 0, y: 0, width: 280, height: 320)
        let rect = DragHandleGeometry.rect(
            in: bounds,
            edge: .right,
            isNotchCloak: false,
            notchOccludedHeight: 0,
            handleOffsetInsidePanel: 160,
            stackLength: 56
        )
        try expectEqual(rect.maxX, bounds.maxX)
        try expectEqual(rect.width, LayoutMetrics.hoverHitThickness)
        try expect(rect.height == 56)
    }

    static func topHandleAccountsForNotchOcclusion() throws {
        let bounds = CGRect(x: 0, y: 0, width: 280, height: 320)
        let occluded: CGFloat = 32
        let rect = DragHandleGeometry.rect(
            in: bounds,
            edge: .top,
            isNotchCloak: true,
            notchOccludedHeight: occluded,
            handleOffsetInsidePanel: 140,
            stackLength: 56
        )
        try expectEqual(rect.maxY, bounds.height - occluded)
        try expect(rect.maxY < bounds.height)
    }

    static func topHandleWithoutNotchSitsAtTop() throws {
        let bounds = CGRect(x: 0, y: 0, width: 280, height: 320)
        let rect = DragHandleGeometry.rect(
            in: bounds,
            edge: .top,
            isNotchCloak: false,
            notchOccludedHeight: 0,
            handleOffsetInsidePanel: 140,
            stackLength: 56
        )
        try expectEqual(rect.maxY, bounds.height)
    }
}
