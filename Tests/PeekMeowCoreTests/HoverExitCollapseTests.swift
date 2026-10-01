import CoreGraphics
import PeekMeowCore

enum HoverExitCollapseTests {
    static func run() throws {
        try leavingExpandedSchedulesCollapse()
        try closeDelayCollapsesWhenPointerStaysOut()
        try reentryCancelsPendingCollapse()
        try staleGapBetweenEdgeAndPanelIsOutside()
        try screenCenterIsOutsideLivePanel()
        try staleCloseTimerDoesNotCollapseWhilePointerInside()
    }

    static func leavingExpandedSchedulesCollapse() throws {
        var engine = HoverEngine(phase: .expanded, pointerInside: true)
        let output = engine.handle(.pointerExitedRegion)
        try expectEqual(output, .scheduleClose(LayoutMetrics.defaultHoverCloseDelay))
        try expectEqual(engine.phase, .expanded)
        try expect(!engine.pointerInside)
        try expect(!engine.isPinned)
    }

    static func closeDelayCollapsesWhenPointerStaysOut() throws {
        var engine = HoverEngine(phase: .expanded, pointerInside: true)
        _ = engine.handle(.pointerExitedRegion)
        let output = engine.handle(.closeDelayElapsed)
        try expectEqual(output, .collapse)
        try expectEqual(engine.phase, .collapsed)
    }

    static func reentryCancelsPendingCollapse() throws {
        var engine = HoverEngine(phase: .expanded, pointerInside: true)
        _ = engine.handle(.pointerExitedRegion)
        let output = engine.handle(.pointerEnteredRegion)
        try expectEqual(output, .cancelTimers)
        try expect(engine.pointerInside)
        try expectEqual(engine.phase, .expanded)
    }

    static func staleGapBetweenEdgeAndPanelIsOutside() throws {
        let edge = CGRect(x: 0, y: 0, width: 14, height: 56)
        let panel = CGRect(x: 400, y: 0, width: 280, height: 320)
        let gap = CGPoint(x: 200, y: 40)
        let hits = HoverRegion.hits(gap, edge: edge, panel: panel, padding: 6)
        try expect(!hits.inside)
        try expect(!hits.insideEdge)
        try expect(!hits.insidePanel)
    }

    static func screenCenterIsOutsideLivePanel() throws {
        let edge = CGRect(x: 1480, y: 500, width: 14, height: 56)
        let panel = CGRect(x: 1200, y: 360, width: 280, height: 320)
        let center = CGPoint(x: 800, y: 500)
        let hits = HoverRegion.hits(center, edge: edge, panel: panel, padding: 6)
        try expect(!hits.insideEdge)
        try expect(!hits.insidePanel)
        try expect(!hits.inside)
        let inside = HoverRegion.hits(
            CGPoint(x: panel.midX, y: panel.midY),
            edge: edge,
            panel: panel
        )
        try expect(inside.insidePanel)
    }

    static func staleCloseTimerDoesNotCollapseWhilePointerInside() throws {
        var engine = HoverEngine(phase: .expanded, pointerInside: true)
        let output = engine.handle(.closeDelayElapsed)
        try expectEqual(output, .none)
        try expectEqual(engine.phase, .expanded)
    }
}
