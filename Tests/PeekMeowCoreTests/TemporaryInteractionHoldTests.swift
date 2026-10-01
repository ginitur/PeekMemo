import PeekMeowCore

enum TemporaryInteractionHoldTests {
    static func run() throws {
        try holdPausesCollapseWithoutPinning()
        try endingHoldOutsideSchedulesCollapse()
        try endingHoldInsideStaysExpanded()
        try nestedHoldsWaitForTheLastEnd()
        try reentryDuringHoldDoesNotCollapse()
    }

    static func holdPausesCollapseWithoutPinning() throws {
        var engine = HoverEngine(phase: .expanded, pointerInside: true)
        let began = engine.handle(.beginInteraction)
        try expectEqual(began, .cancelTimers)
        try expectEqual(engine.interactionHoldCount, 1)
        try expectEqual(engine.phase, .expanded)
        try expect(!engine.isPinned)
        let exit = engine.handle(.pointerExitedRegion)
        try expectEqual(exit, .none)
        try expectEqual(engine.phase, .expanded)
        try expect(!engine.pointerInside)
    }

    static func endingHoldOutsideSchedulesCollapse() throws {
        var engine = HoverEngine(phase: .expanded, pointerInside: true)
        _ = engine.handle(.beginInteraction)
        _ = engine.handle(.pointerExitedRegion)
        let ended = engine.handle(.endInteraction)
        try expectEqual(ended, .scheduleClose(engine.closeDelay))
        try expectEqual(engine.phase, .expanded)
        try expect(!engine.isPinned)
        try expectEqual(engine.interactionHoldCount, 0)
    }

    static func endingHoldInsideStaysExpanded() throws {
        var engine = HoverEngine(phase: .expanded, pointerInside: true)
        _ = engine.handle(.beginInteraction)
        let ended = engine.handle(.endInteraction)
        try expectEqual(ended, .none)
        try expectEqual(engine.phase, .expanded)
        try expect(engine.pointerInside)
        try expect(!engine.isPinned)
    }

    static func nestedHoldsWaitForTheLastEnd() throws {
        var engine = HoverEngine(phase: .expanded, pointerInside: true)
        _ = engine.handle(.beginInteraction)
        _ = engine.handle(.beginInteraction)
        _ = engine.handle(.pointerExitedRegion)
        let first = engine.handle(.endInteraction)
        try expectEqual(first, .none)
        try expectEqual(engine.interactionHoldCount, 1)
        try expectEqual(engine.phase, .expanded)
        let second = engine.handle(.endInteraction)
        try expectEqual(second, .scheduleClose(engine.closeDelay))
        try expectEqual(engine.interactionHoldCount, 0)
    }

    static func reentryDuringHoldDoesNotCollapse() throws {
        var engine = HoverEngine(phase: .expanded, pointerInside: true)
        _ = engine.handle(.beginInteraction)
        _ = engine.handle(.pointerExitedRegion)
        let back = engine.handle(.pointerEnteredRegion)
        try expectEqual(back, .cancelTimers)
        try expect(engine.pointerInside)
        let ended = engine.handle(.endInteraction)
        try expectEqual(ended, .none)
        try expectEqual(engine.phase, .expanded)
    }
}
