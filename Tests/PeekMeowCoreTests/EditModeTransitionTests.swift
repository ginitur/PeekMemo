import PeekMeowCore

enum EditModeTransitionTests {
    static func run() throws {
        try editAllowsKeyAndIgnoresExit()
        try endEditReturnsToExpandedPeek()
        try endEditOutsideSchedulesCollapse()
        try endEditInsideKeepsPeekOpen()
        try editDoesNotPin()
    }

    static func editAllowsKeyAndIgnoresExit() throws {
        var engine = HoverEngine(phase: .expanded, pointerInside: true)
        let began = engine.handle(.doubleClick)
        try expectEqual(began, .beginEditing)
        try expectEqual(engine.phase, .editing)
        try expect(engine.allowsKeyWindow)
        let exit = engine.handle(.pointerExitedRegion)
        try expectEqual(exit, .none)
        try expectEqual(engine.phase, .editing)
        try expect(!engine.pointerInside)
        try expect(engine.allowsKeyWindow)
    }

    static func endEditReturnsToExpandedPeek() throws {
        var engine = HoverEngine(phase: .editing, pointerInside: true)
        let ended = engine.handle(.endEditing)
        try expectEqual(ended, .endEditing)
        try expectEqual(engine.phase, .expanded)
        try expect(!engine.allowsKeyWindow)
        try expect(!engine.isPinned)
    }

    static func endEditOutsideSchedulesCollapse() throws {
        var engine = HoverEngine(phase: .editing, pointerInside: false)
        _ = engine.handle(.endEditing)
        try expectEqual(engine.phase, .expanded)
        let close = engine.handle(.pointerExitedRegion)
        try expectEqual(close, .scheduleClose(engine.closeDelay))
        let collapsed = engine.handle(.closeDelayElapsed)
        try expectEqual(collapsed, .collapse)
        try expectEqual(engine.phase, .collapsed)
        try expect(!engine.allowsKeyWindow)
    }

    static func endEditInsideKeepsPeekOpen() throws {
        var engine = HoverEngine(phase: .editing, pointerInside: true)
        _ = engine.handle(.endEditing)
        try expect(engine.pointerInside)
        try expectEqual(engine.phase, .expanded)
        let ignored = engine.handle(.closeDelayElapsed)
        try expectEqual(ignored, .none)
        try expectEqual(engine.phase, .expanded)
    }

    static func editDoesNotPin() throws {
        var engine = HoverEngine(phase: .expanded, pointerInside: true)
        _ = engine.handle(.doubleClick)
        _ = engine.handle(.endEditing)
        try expect(!engine.isPinned)
        try expectEqual(engine.phase, .expanded)
    }
}
