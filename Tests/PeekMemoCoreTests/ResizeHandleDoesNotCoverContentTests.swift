import CoreGraphics
import Foundation
import PeekMemoCore

enum ResizeHandleDoesNotCoverContentTests {
    static func run() throws {
        for edge in [ScreenEdge.right, .left, .bottom] {
            for size in [CGSize(width: 340, height: 460), CGSize(width: 280, height: 300)] {
                try contentPointsStayOutsideTheGrip(edge: edge, size: size)
            }
        }
    }

    static func contentPointsStayOutsideTheGrip(edge: ScreenEdge, size: CGSize) throws {
        let content = CGRect(origin: .zero, size: size)
        let probe = PanelResizeGeometry.contentProbe(content: content, edge: edge)
        let handle = probe.resizeHandleRect
        try expect(handle.width * handle.height / (content.width * content.height) < 0.05)
        for point in [probe.dateHeader, probe.categoryButton, probe.taskRow, probe.addTask, probe.center] {
            try expect(!probe.hitsResize(point), "\(edge) \(size) \(point) is inside \(handle)")
        }
        try expect(probe.hitsResize(probe.corner), "\(edge) corner should hit")
    }
}
