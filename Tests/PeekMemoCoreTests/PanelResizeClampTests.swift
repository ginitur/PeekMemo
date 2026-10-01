import CoreGraphics
import Foundation
import PeekMemoCore

enum PanelResizeClampTests {
    static func run() throws {
        try screenClampKeepsTheWindowInsideTheVisibleFrame()
        try tinyScreenWinsOverTheMinimum()
        try horizontalEdgeReservesTheHitRail()
        try aspectRatioIsNotLocked()
    }

    static func screenClampKeepsTheWindowInsideTheVisibleFrame() throws {
        let visible = CGSize(width: 500, height: 420)
        let display = PanelSizeMetrics.clampToScreen(
            PanelContentSize(width: 420, height: 560),
            visible: visible,
            edgeIsVertical: true
        )
        try expectEqual(display.width, 420)
        try expectEqual(display.height, 420)
        let window = PanelSizeMetrics.windowSize(content: display, edgeIsVertical: true)
        try expect(window.width <= visible.width)
        try expect(window.height <= visible.height)

        let tight = PanelSizeMetrics.clampToScreen(
            PanelContentSize(width: 420, height: 460),
            visible: CGSize(width: 400, height: 800),
            edgeIsVertical: true
        )
        try expectEqual(tight.width, 400 - LayoutMetrics.hoverHitThickness)
        try expectEqual(tight.height, 460)
        let tightWindow = PanelSizeMetrics.windowSize(content: tight, edgeIsVertical: true)
        try expect(tightWindow.width <= 400)
    }

    static func tinyScreenWinsOverTheMinimum() throws {
        let display = PanelSizeMetrics.clampToScreen(
            PanelContentSize(width: 340, height: 460),
            visible: CGSize(width: 200, height: 220),
            edgeIsVertical: true
        )
        try expect(display.width <= 200 - LayoutMetrics.hoverHitThickness)
        try expect(display.height <= 220)
        try expect(display.height < PanelSizeMetrics.minimumHeight)
    }

    static func horizontalEdgeReservesTheHitRail() throws {
        let visible = CGSize(width: 800, height: 320)
        let display = PanelSizeMetrics.clampToScreen(
            PanelContentSize(width: 420, height: 560),
            visible: visible,
            edgeIsVertical: false
        )
        try expectEqual(display.width, 420)
        try expectEqual(display.height, 320 - LayoutMetrics.hoverHitThickness)
        let window = PanelSizeMetrics.windowSize(content: display, edgeIsVertical: false)
        try expect(window.height <= visible.height)
        try expectEqual(window.width, 420)
    }

    static func aspectRatioIsNotLocked() throws {
        let wide = AppearancePreferences(panelSizeMode: .custom, panelWidth: 400, panelHeight: 320)
        let tall = AppearancePreferences(panelSizeMode: .custom, panelWidth: 300, panelHeight: 600)
        try expect(wide.panelWidth > wide.panelHeight)
        try expect(tall.panelHeight > tall.panelWidth)
        try expect(abs((wide.panelWidth / wide.panelHeight) - (tall.panelWidth / tall.panelHeight)) > 0.2)
    }
}
