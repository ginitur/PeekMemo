import PeekMemoCore

enum HoverEngineTests {
    static func run() throws {
        try enterWaitsThenExpands()
        try leaveDuringDelayCancelsOpen()
        try leaveExpandedSchedulesClose()
        try reenteringPanelCancelsClose()
        try clickPinsAndSecondClickCollapses()
        try pinnedIgnoresPointerExit()
        try doubleClickEntersEditingAndAllowsKey()
        try delaysComeFromSettings()
    }

    static func enterWaitsThenExpands() throws {
        var engine = HoverEngine()
        let scheduled = engine.handle(.pointerEnteredRegion)
        try expectEqual(engine.phase, .hovering)
        try expectEqual(scheduled, .scheduleOpen(LayoutMetrics.defaultHoverOpenDelay))

        let opened = engine.handle(.openDelayElapsed)
        try expectEqual(engine.phase, .expanded)
        try expectEqual(opened, .expand)
        try expect(engine.isVisuallyExpanded)
        try expect(!engine.allowsKeyWindow)
    }

    static func leaveDuringDelayCancelsOpen() throws {
        var engine = HoverEngine()
        _ = engine.handle(.pointerEnteredRegion)
        let cancelled = engine.handle(.pointerExitedRegion)
        try expectEqual(engine.phase, .collapsed)
        try expectEqual(cancelled, .cancelTimers)
    }

    static func leaveExpandedSchedulesClose() throws {
        var engine = HoverEngine(phase: .expanded)
        let close = engine.handle(.pointerExitedRegion)
        try expectEqual(close, .scheduleClose(LayoutMetrics.defaultHoverCloseDelay))
        try expectEqual(engine.phase, .expanded)

        let collapsed = engine.handle(.closeDelayElapsed)
        try expectEqual(collapsed, .collapse)
        try expectEqual(engine.phase, .collapsed)
    }

    static func reenteringPanelCancelsClose() throws {
        var engine = HoverEngine(phase: .expanded)
        _ = engine.handle(.pointerExitedRegion)
        let cancel = engine.handle(.pointerEnteredRegion)
        try expectEqual(cancel, .cancelTimers)
        try expectEqual(engine.phase, .expanded)
    }

    static func clickPinsAndSecondClickCollapses() throws {
        var engine = HoverEngine(phase: .expanded)
        _ = engine.handle(.click)
        try expectEqual(engine.phase, .pinned)
        let output = engine.handle(.click)
        try expectEqual(engine.phase, .collapsed)
        try expectEqual(output, .collapse)
    }

    static func pinnedIgnoresPointerExit() throws {
        var engine = HoverEngine(phase: .pinned)
        let output = engine.handle(.pointerExitedRegion)
        try expectEqual(output, .none)
        try expectEqual(engine.phase, .pinned)
    }

    static func doubleClickEntersEditingAndAllowsKey() throws {
        var engine = HoverEngine(phase: .expanded)
        let output = engine.handle(.doubleClick)
        try expectEqual(output, .beginEditing)
        try expectEqual(engine.phase, .editing)
        try expect(engine.allowsKeyWindow)

        _ = engine.handle(.pointerExitedRegion)
        try expectEqual(engine.phase, .editing)

        _ = engine.handle(.endEditing)
        try expectEqual(engine.phase, .pinned)
        try expect(!engine.allowsKeyWindow)
    }

    static func delaysComeFromSettings() throws {
        var engine = HoverEngine(openDelay: 0.2, closeDelay: 0.4)
        try expectEqual(engine.handle(.pointerEnteredRegion), .scheduleOpen(0.2))

        var expanded = HoverEngine(phase: .expanded, openDelay: 0.2, closeDelay: 0.4)
        try expectEqual(expanded.handle(.pointerExitedRegion), .scheduleClose(0.4))
    }
}
