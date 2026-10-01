import CoreGraphics
import Foundation
import PeekMemoCore

enum PanelSizingPreferenceTests {
    static func run() throws {
        try compactWindowAddsTheHitRail()
        try shortContentDoesNotUseTheMaxHeight()
        try overflowCapsTheBodyViewport()
        try presetsChangeTheColumn()
        try hitRegionIgnoresVisualThickness()
    }

    static func compactWindowAddsTheHitRail() throws {
        let prefs = AppearancePreferences.default
        let size = prefs.expandedWindowSize(edgeIsVertical: true, header: 44, body: 80)
        try expectEqual(size.width, 280 + LayoutMetrics.hoverHitThickness)
        try expectEqual(prefs.contentColumnHeight(header: 44, body: 80), 124)
        try expectEqual(size.height, 124)
        let horizontal = prefs.expandedWindowSize(edgeIsVertical: false, header: 44, body: 80)
        try expectEqual(horizontal.width, 280)
        try expectEqual(horizontal.height, 124 + LayoutMetrics.hoverHitThickness)
    }

    static func shortContentDoesNotUseTheMaxHeight() throws {
        let prefs = AppearancePreferences.default
        let column = prefs.contentColumnHeight(header: 44, body: 30)
        try expectEqual(column, AppearancePreferences.minimumContentHeight)
        try expect(column < prefs.panelHeightPreset.maxContentHeight)
        try expectEqual(prefs.bodyViewport(header: 44, body: 30), 30)
    }

    static func overflowCapsTheBodyViewport() throws {
        let prefs = AppearancePreferences.default
        try expectEqual(prefs.panelHeightPreset.maxContentHeight, 420)
        let column = prefs.contentColumnHeight(header: 50, body: 900)
        try expectEqual(column, 420)
        try expectEqual(prefs.bodyViewport(header: 50, body: 900), 370)
    }

    static func presetsChangeTheColumn() throws {
        let wide = AppearancePreferences(panelWidthPreset: .wide, panelHeightPreset: .large)
        let size = wide.expandedWindowSize(edgeIsVertical: true, header: 40, body: 800)
        try expectEqual(size.width, 420 + 14)
        try expectEqual(size.height, 560)
        let small = AppearancePreferences(panelWidthPreset: .medium, panelHeightPreset: .small)
        try expectEqual(small.expandedWindowSize(edgeIsVertical: false, header: 40, body: 800).width, 340)
        try expectEqual(small.contentColumnHeight(header: 40, body: 800), 280)
        try expectEqual(small.bodyViewport(header: 40, body: 800), 240)
    }

    static func hitRegionIgnoresVisualThickness() throws {
        for thickness in [CGFloat(2), 3, 6] {
            for length in [CGFloat(32), 56, 96] {
                let prefs = AppearancePreferences(edgeTabThickness: thickness, edgeTabLength: length)
                try expectEqual(prefs.edgeTabThickness, thickness)
                try expectEqual(prefs.edgeTabLength, length)
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
}
