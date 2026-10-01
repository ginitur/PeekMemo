import CoreGraphics
import Foundation
import PeekMemoCore

enum ResizeHandleRectTests {
    static func run() throws {
        try hitSizeIsAtMost24()
        try stableEdgesSitOnTheFreeCorner()
        try aCardSizedViewStillClaimsOnlyTheCorner()
    }

    static func hitSizeIsAtMost24() throws {
        try expect(PanelResizeGeometry.gripSize <= PanelResizeGeometry.maximumHitSize)
        try expect(PanelResizeGeometry.gripSize <= 24)
        try expect(PanelResizeGeometry.visualGripSize < PanelResizeGeometry.gripSize)
        try expectEqual(PanelResizeGeometry.visualGripSize, 14)
        try expectEqual(PanelResizeGeometry.gripInset, 6)
        let content = CGRect(x: 0, y: 0, width: 340, height: 460)
        for edge in [ScreenEdge.right, .left, .bottom] {
            let handle = PanelResizeGeometry.gripFrame(in: content, edge: edge)
            try expect(handle.width <= 24, "\(edge) width \(handle.width)")
            try expect(handle.height <= 24, "\(edge) height \(handle.height)")
            try expectEqual(handle.width, 22)
            try expectEqual(handle.height, 22)
        }
    }

    static func stableEdgesSitOnTheFreeCorner() throws {
        let content = CGRect(x: 10, y: 20, width: 340, height: 460)
        let right = PanelResizeGeometry.gripFrame(in: content, edge: .right)
        try expectEqual(right.minX, content.minX + 6)
        try expectEqual(right.minY, content.minY + 6)
        let left = PanelResizeGeometry.gripFrame(in: content, edge: .left)
        try expectEqual(left.maxX, content.maxX - 6)
        try expectEqual(left.minY, content.minY + 6)
        let bottom = PanelResizeGeometry.gripFrame(in: content, edge: .bottom)
        try expectEqual(bottom.maxX, content.maxX - 6)
        try expectEqual(bottom.maxY, content.maxY - 6)
    }

    static func aCardSizedViewStillClaimsOnlyTheCorner() throws {
        let card = CGRect(x: 0, y: 0, width: 340, height: 460)
        let claimed = PanelResizeGeometry.flippedHitRect(in: card, corner: .bottomLeft)
        try expectEqual(claimed.width, 22)
        try expectEqual(claimed.height, 22)
        try expectEqual(claimed.minX, 0)
        try expectEqual(claimed.maxY, card.maxY)
        let center = CGPoint(x: card.midX, y: card.midY)
        try expect(!claimed.contains(center))
        let date = CGPoint(x: 72, y: 24)
        try expect(!claimed.contains(date))
    }
}
