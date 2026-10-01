import AppKit
import PeekMeowCore

/// AppKit owner of `HoverEngine`. Uses delayed work items, never a polling timer.
@MainActor
final class HoverController {
    private(set) var engine: HoverEngine
    var isDragging = false
    var regionContainsPointer: () -> Bool = { false }
    var onOutput: ((HoverOutput) -> Void)?

    private var openWork: DispatchWorkItem?
    private var closeWork: DispatchWorkItem?
    private var graceWork: DispatchWorkItem?

    init(engine: HoverEngine = HoverEngine()) {
        self.engine = engine
    }

    /// Next hover uses these delays. An in-flight open or close timer is rescheduled.
    func setDelays(open: TimeInterval, close: TimeInterval) {
        let openChanged = engine.openDelay != open
        let closeChanged = engine.closeDelay != close
        engine.openDelay = open
        engine.closeDelay = close
        if openChanged, openWork != nil {
            apply(.scheduleOpen(open))
        }
        if closeChanged, closeWork != nil {
            apply(.scheduleClose(close))
        }
    }

    func pointerEntered() {
        guard !isDragging else { return }
        graceWork?.cancel()
        graceWork = nil
        apply(engine.handle(.pointerEnteredRegion))
    }

    func pointerExited() {
        guard !isDragging else { return }
        // A move outside while the grace timer is already running must not
        // push the collapse further out.
        if graceWork != nil { return }
        let work = DispatchWorkItem { [weak self] in
            self?.confirmExit()
        }
        graceWork = work
        DispatchQueue.main.asyncAfter(
            deadline: .now() + LayoutMetrics.hoverGracePeriod,
            execute: work
        )
    }

    func click() {
        guard !isDragging else { return }
        graceWork?.cancel()
        graceWork = nil
        apply(engine.handle(.click))
    }

    func enterEditing() {
        guard !isDragging else { return }
        graceWork?.cancel()
        graceWork = nil
        apply(engine.handle(.doubleClick))
    }

    func exitEditing() {
        apply(engine.handle(.endEditing))
        if engine.phase == .expanded, !engine.pointerInside, engine.interactionHoldCount == 0 {
            apply(engine.handle(.pointerExitedRegion))
        }
    }

    func beginInteraction() {
        guard !isDragging else { return }
        graceWork?.cancel()
        graceWork = nil
        apply(engine.handle(.beginInteraction))
    }

    func endInteraction() {
        guard !isDragging else { return }
        apply(engine.handle(.endInteraction))
    }

    var isExitGracePending: Bool { graceWork != nil }

    func beginDrag() {
        isDragging = true
        cancelAll()
        engine.resetToCollapsed()
        onOutput?(.collapse)
    }

    func endDrag() {
        isDragging = false
    }

    func forceCollapse() {
        isDragging = false
        cancelAll()
        engine.resetToCollapsed()
        onOutput?(.collapse)
    }

    private func confirmExit() {
        graceWork = nil
        if regionContainsPointer() {
            pointerEntered()
            return
        }
        apply(engine.handle(.pointerExitedRegion))
    }

    private func apply(_ output: HoverOutput) {
        switch output {
        case .none:
            break
        case .scheduleOpen(let delay):
            cancelOpenAndClose()
            let work = DispatchWorkItem { [weak self] in
                guard let self else { return }
                self.apply(self.engine.handle(.openDelayElapsed))
            }
            openWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
        case .scheduleClose(let delay):
            cancelOpenAndClose()
            let work = DispatchWorkItem { [weak self] in
                guard let self else { return }
                self.apply(self.engine.handle(.closeDelayElapsed))
            }
            closeWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
        case .cancelTimers:
            cancelOpenAndClose()
        case .expand, .collapse, .beginEditing, .endEditing:
            cancelOpenAndClose()
        }
        onOutput?(output)
    }

    private func cancelOpenAndClose() {
        openWork?.cancel()
        closeWork?.cancel()
        openWork = nil
        closeWork = nil
    }

    private func cancelAll() {
        cancelOpenAndClose()
        graceWork?.cancel()
        graceWork = nil
    }
}
