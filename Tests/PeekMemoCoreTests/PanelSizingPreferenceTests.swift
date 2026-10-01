import CoreGraphics
import Foundation
import PeekMemoCore

enum PanelSizingPreferenceTests {
    static func run() throws {
        try defaultCardIsTallerThanItIsWide()
        try shortContentDoesNotShrinkTheCard()
        try minimumSizeIsASmallNote()
        try presetsUseFixedCards()
        try hitRegionIgnoresVisualThickness()
        try edgeTabLengthIsIndependentOfPanelSize()
    }

    static func defaultCardIsTallerThanItIsWide() throws {
        let prefs = AppearancePreferences.default
        try expectEqual(prefs.panelSizeMode, .medium)
        try expectEqual(prefs.panelWidth, 340)
        try expectEqual(prefs.panelHeight, 460)
        let visible = CGSize(width: 1512, height: 944)
        let window = prefs.windowSize(edgeIsVertical: true, visible: visible)
        try expectEqual(window.width, 340 + LayoutMetrics.hoverHitThickness)
        try expectEqual(window.height, 460)
        try expect(window.height > window.width)
        let horizontal = prefs.windowSize(edgeIsVertical: false, visible: visible)
        try expectEqual(horizontal.width, 340)
        try expectEqual(horizontal.height, 460 + LayoutMetrics.hoverHitThickness)
    }

    static func shortContentDoesNotShrinkTheCard() throws {
        let prefs = AppearancePreferences.default
        let visible = CGSize(width: 1440, height: 900)
        let display = prefs.displayContentSize(visible: visible, edgeIsVertical: true)
        try expectEqual(display.height, prefs.panelHeight)
        try expect(display.height > PanelSizeMetrics.minimumHeight)
        try expect(display.height > 120, "empty days must not collapse to a header strip")
    }

    static func minimumSizeIsASmallNote() throws {
        let tiny = AppearancePreferences(panelSizeMode: .custom, panelWidth: 100, panelHeight: 40)
        try expectEqual(tiny.panelWidth, PanelSizeMetrics.minimumWidth)
        try expectEqual(tiny.panelHeight, PanelSizeMetrics.minimumHeight)
        try expectEqual(PanelSizeMetrics.minimumWidth, 280)
        try expectEqual(PanelSizeMetrics.minimumHeight, 300)
    }

    static func presetsUseFixedCards() throws {
        let small = AppearancePreferences(panelSizeMode: .small, panelWidth: 999, panelHeight: 999)
        try expectEqual(small.panelWidth, 300)
        try expectEqual(small.panelHeight, 360)
        let large = AppearancePreferences(panelSizeMode: .large)
        try expectEqual(large.panelWidth, 420)
        try expectEqual(large.panelHeight, 560)
        let visible = CGSize(width: 1600, height: 1000)
        try expectEqual(large.windowSize(edgeIsVertical: true, visible: visible).width, 420 + 14)
        try expectEqual(large.windowSize(edgeIsVertical: true, visible: visible).height, 560)
    }

    static func hitRegionIgnoresVisualThickness() throws {
        for thickness in [CGFloat(2), 3, 6] {
            for length in [CGFloat(32), 56, 96] {
                let prefs = AppearancePreferences(
                    panelSizeMode: .custom,
                    panelWidth: 368,
                    panelHeight: 512,
                    edgeTabThickness: thickness,
                    edgeTabLength: length
                )
                try expectEqual(prefs.edgeTabThickness, thickness)
                try expectEqual(prefs.edgeTabLength, length)
                try expectEqual(prefs.panelWidth, 368)
                try expectEqual(prefs.hitRegionThickness, 14)
                let vertical = EdgeGeometry.collapsedWindowSize(edge: .right, stackLength: length)
                try expectEqual(vertical.width, LayoutMetrics.hoverHitThickness)
                try expectEqual(vertical.height, length)
                let horizontal = EdgeGeometry.collapsedWindowSize(edge: .bottom, stackLength: length)
                try expectEqual(horizontal.height, LayoutMetrics.hoverHitThickness)
                try expectEqual(horizontal.width, length)
            }
        }
    }

    static func edgeTabLengthIsIndependentOfPanelSize() throws {
        let wide = AppearancePreferences(panelSizeMode: .large)
        let narrow = AppearancePreferences(panelSizeMode: .small)
        try expectEqual(wide.edgeTabLength, narrow.edgeTabLength)
        try expectEqual(wide.hitRegionThickness, narrow.hitRegionThickness)
    }
}
