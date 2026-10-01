import CoreGraphics
import Foundation
import PeekMemoCore

enum ResizeHitTestingTests {
    static func run() throws {
        try onlyTheCornerStartsAResize()
        try pointsJustOutsideTheSquareDoNotHit()
        try theOppositeCornerDoesNotHit()
    }

    static func onlyTheCornerStartsAResize() throws {
        let content = CGRect(x: 0, y: 0, width: 340, height: 460)
        for edge in [ScreenEdge.right, .left, .bottom] {
            let probe = PanelResizeGeometry.contentProbe(content: content, edge: edge)
            try expect(PanelResizeGeometry.beginsResize(at: probe.corner, content: content, edge: edge))
            try expect(!PanelResizeGeometry.beginsResize(at: probe.dateHeader, content: content, edge: edge))
            try expect(!PanelResizeGeometry.beginsResize(at: probe.categoryButton, content: content, edge: edge))
            try expect(!PanelResizeGeometry.beginsResize(at: probe.taskRow, content: content, edge: edge))
            try expect(!PanelResizeGeometry.beginsResize(at: probe.addTask, content: content, edge: edge))
            try expect(!PanelResizeGeometry.beginsResize(at: probe.center, content: content, edge: edge))
        }
    }

    static func pointsJustOutsideTheSquareDoNotHit() throws {
        let content = CGRect(x: 0, y: 0, width: 340, height: 460)
        let handle = PanelResizeGeometry.gripFrame(in: content, edge: .right)
        let outside = [
            CGPoint(x: handle.minX - 1, y: handle.midY),
            CGPoint(x: handle.maxX + 1, y: handle.midY),
            CGPoint(x: handle.midX, y: handle.minY - 1),
            CGPoint(x: handle.midX, y: handle.maxY + 1),
        ]
        for point in outside {
            try expect(!handle.contains(point), "\(point) should miss \(handle)")
            try expect(!PanelResizeGeometry.beginsResize(at: point, content: content, edge: .right))
        }
        try expect(handle.contains(CGPoint(x: handle.minX, y: handle.minY)))
    }

    static func theOppositeCornerDoesNotHit() throws {
        let content = CGRect(x: 0, y: 0, width: 340, height: 460)
        let right = PanelResizeGeometry.gripFrame(in: content, edge: .right)
        let far = CGPoint(x: content.maxX - 12, y: content.maxY - 12)
        try expect(!right.contains(far))
        let bottom = PanelResizeGeometry.gripFrame(in: content, edge: .bottom)
        let lowerLeft = CGPoint(x: content.minX + 12, y: content.minY + 12)
        try expect(!bottom.contains(lowerLeft))
    }
}
