import AppKit
import PeekMemoCore
import SwiftUI

/// Owns the floating edge panel: placement, Notch Cloak, and hover reveal.
@MainActor
final class PanelController {
    private let panel = PeekPanel()
    private let positionManager = PanelPositionManager()
    private let hostView = EdgeHostView()
    private let hover = HoverController()
    private var hostingView: NSHostingView<PeekRootView>?
    private var anchorPlacement: PanelPlacement?
    private var screenChangeObserver: (any NSObjectProtocol)?
    private let notchDebugOverlay = NotchDebugOverlay()
    private let notchSensor = NotchActivationSensor()
    private var shellExpanded = false
    private var contentOpacity: Double = 1
    private var motionGeneration = 0
    private var suppressAnimatedCollapse = false
    private let appState = AppState()
    private var currentExpansion: ExpansionLayout?
    private var outsideMoveMonitor: Any?
    private var editorScreenRect: CGRect?
    #if DEBUG
    private var lastInteractionLog: InteractionLogKey?
    #endif

    private var previewSize: CGSize {
        CGSize(width: LayoutMetrics.previewPanelWidth, height: LayoutMetrics.previewPanelHeight)
    }

    init() {
        hostView.wantsLayer = true
        hostView.layer?.backgroundColor = NSColor.clear.cgColor
        hostView.onDragBegan = { [weak self] in
            guard let self else { return }
            self.motionGeneration += 1
            self.shellExpanded = false
            self.contentOpacity = 1
            self.notchSensor.hide()
            self.hover.beginDrag()
            self.syncChrome(animated: false)
        }
        hostView.onDrag = { [weak self] point in
            self?.handleDrag(at: point)
        }
        hostView.onDragEnded = { [weak self] point in
            self?.handleDragEnded(at: point)
        }
        hostView.onClick = { [weak self] in
            self?.hover.click()
        }
        hostView.onPointerEntered = { [weak self] in
            self?.probeNotchHit(at: NSEvent.mouseLocation)
            self?.hover.pointerEntered()
        }
        hostView.onPointerExited = { [weak self] in
            self?.probeNotchHit(at: NSEvent.mouseLocation)
            self?.hover.pointerExited()
        }
        hostView.onPointerMoved = { [weak self] point in
            self?.probeNotchHit(at: point)
            self?.evaluatePointer()
        }
        hover.regionContainsPointer = { [weak self] in
            self?.pointerIsInsideHoverRegion() ?? false
        }
        hover.onOutput = { [weak self] output in
            self?.handleHoverOutput(output)
        }
        panel.contentView = hostView
        panel.allowsKey = false
        notchSensor.onEnter = { [weak self] in
            self?.hover.pointerEntered()
        }
        notchSensor.onExit = { [weak self] in
            self?.hover.pointerExited()
        }
        observeScreenChanges()
    }

    func showRestoredOrDefault() {
        guard let screen = ScreenManager.mainSnapshot() else {
            return
        }
        let stored = PlacementStore.placement(for: screen.identifier)
            ?? DisplayPlacement(
                displayIdentifier: screen.identifier,
                edge: AppSettings.default.selectedEdge,
                offset: AppSettings.default.edgeOffset
            )
        setAnchor(
            EdgeGeometry.placement(
                from: stored,
                screen: screen,
                stackLength: positionManager.stackLength
            ),
            persist: false
        )
        panel.orderFrontRegardless()
    }

    func hide() {
        stopOutsideMonitor()
        panel.orderOut(nil)
    }

    func resetPosition() {
        guard let screen = ScreenManager.mainSnapshot() else {
            return
        }
        suppressAnimatedCollapse = true
        hover.forceCollapse()
        suppressAnimatedCollapse = false
        let stored = DisplayPlacement(
            displayIdentifier: screen.identifier,
            edge: .right,
            offset: AppSettings.default.edgeOffset
        )
        PlacementStore.upsert(stored)
        setAnchor(
            EdgeGeometry.placement(
                from: stored,
                screen: screen,
                stackLength: positionManager.stackLength
            ),
            persist: false
        )
        panel.orderFrontRegardless()
    }

    func refreshChrome() {
        syncChrome(animated: false)
    }

    func moveToNotchCloak() {
        PlacementPolicy.allowTopEdgeSnap = true
        PlacementPolicy.allowNotchCloak = true
        #if DEBUG
        DebugFlags.experimentalTopEdge = true
        #endif
        guard let screen = ScreenManager.mainSnapshot(),
              NotchGeometry.region(on: screen) != nil
        else { return }
        suppressAnimatedCollapse = true
        hover.forceCollapse()
        suppressAnimatedCollapse = false
        let stored = DisplayPlacement(
            displayIdentifier: screen.identifier,
            edge: .top,
            offset: NotchGeometry.cloakOffset(
                stackLength: positionManager.stackLength,
                screen: screen
            ),
            isNotchCloak: true
        )
        PlacementStore.upsert(stored)
        setAnchor(
            EdgeGeometry.placement(
                from: stored,
                screen: screen,
                stackLength: positionManager.stackLength
            ),
            persist: false
        )
        panel.orderFrontRegardless()
    }

    func reposition() {
        let screens = ScreenManager.allSnapshots()
        guard let main = ScreenManager.mainSnapshot() ?? screens.first else {
            hide()
            return
        }
        let saved = anchorPlacement?.stored
            ?? PlacementStore.placement(for: main.identifier)
            ?? DisplayPlacement(
                displayIdentifier: main.identifier,
                edge: .right,
                offset: AppSettings.default.edgeOffset
            )
        let resolved = ScreenMigration.resolve(
            saved: saved,
            screens: screens,
            mainScreenID: main.identifier
        )
        guard let screen = resolved.screen else {
            hide()
            return
        }
        setAnchor(
            EdgeGeometry.placement(
                from: resolved.placement,
                screen: screen,
                stackLength: positionManager.stackLength
            ),
            persist: true
        )
    }

    private func handleDrag(at point: CGPoint) {
        guard let screen = screen(for: point) else { return }
        let grab = anchorPlacement?.frame.size
            ?? EdgeGeometry.collapsedWindowSize(edge: .right, stackLength: positionManager.stackLength)
        let placement = EdgeGeometry.draggingPlacement(
            pointer: point,
            screen: screen,
            stackLength: positionManager.stackLength,
            grabSize: grab
        )
        setAnchor(placement, persist: false, animated: false)
    }

    private func handleDragEnded(at point: CGPoint) {
        guard let screen = screen(for: point) else {
            hover.endDrag()
            return
        }
        let placement = EdgeGeometry.committedPlacement(
            pointer: point,
            screen: screen,
            stackLength: positionManager.stackLength
        )
        setAnchor(placement, persist: true, animated: false)
        hover.endDrag()
    }

    private func handleHoverOutput(_ output: HoverOutput) {
        switch output {
        case .expand:
            startOutsideMonitor()
            expandChrome()
        case .beginEditing:
            startOutsideMonitor()
            if !shellExpanded {
                expandChrome()
            }
            enterKeyMode()
        case .endEditing:
            exitKeyMode()
        case .collapse:
            stopOutsideMonitor()
            editorScreenRect = nil
            if hover.isDragging || suppressAnimatedCollapse {
                motionGeneration += 1
                shellExpanded = false
                contentOpacity = 1
                syncChrome(animated: false)
            } else {
                collapseChrome()
            }
        case .none, .scheduleOpen, .scheduleClose, .cancelTimers:
            break
        }
        if hover.engine.isPinned || hover.engine.phase == .collapsed {
            stopOutsideMonitor()
        }
        publishInteractionLog(at: NSEvent.mouseLocation)
    }

    private func expandChrome() {
        motionGeneration += 1
        let generation = motionGeneration
        shellExpanded = true
        contentOpacity = 0
        syncChrome(
            animated: !hover.isDragging,
            expanding: true,
            duration: LayoutMetrics.expandDuration
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + LayoutMetrics.contentFadeDelay) { [weak self] in
            guard let self, self.motionGeneration == generation else { return }
            self.contentOpacity = 1
            self.refreshPresentedContent()
        }
    }

    private func collapseChrome() {
        motionGeneration += 1
        let generation = motionGeneration
        contentOpacity = 0
        refreshPresentedContent()
        DispatchQueue.main.asyncAfter(deadline: .now() + LayoutMetrics.contentFadeOutDuration) { [weak self] in
            guard let self, self.motionGeneration == generation else { return }
            self.shellExpanded = false
            self.syncChrome(
                animated: !self.hover.isDragging,
                expanding: false,
                duration: LayoutMetrics.collapseDuration
            )
        }
    }

    private func setAnchor(
        _ placement: PanelPlacement,
        persist: Bool,
        animated: Bool = false
    ) {
        anchorPlacement = placement
        if persist {
            PlacementStore.upsert(placement.stored)
        }
        syncChrome(animated: animated)
    }

    private func syncChrome(
        animated: Bool,
        expanding: Bool = true,
        duration: TimeInterval = LayoutMetrics.expandDuration
    ) {
        guard let anchor = anchorPlacement else { return }
        let framePlacement = displayedPlacement(anchor: anchor, expanded: shellExpanded)
        panel.allowNotchPlacement = anchor.isNotchCloak
        let requested = framePlacement.frame
        positionManager.apply(
            framePlacement,
            to: panel,
            animated: animated,
            expanding: expanding,
            duration: duration
        )
        if animated {
            let wait = duration
            DispatchQueue.main.asyncAfter(deadline: .now() + wait) { [weak self] in
                self?.finishFrameAnimation()
            }
        } else {
            finishFrameAnimation()
        }
        refreshPresentedContent()
        refreshNotchDebugOverlay()
        refreshNotchSensor(anchor: anchor)
        logNotchFrames(requested: requested, anchor: anchor)
        if DebugFlags.showAnchorGeometry, let expansion = currentExpansion {
            print(
                "[Anchor] offset=\(anchor.offset) point=\(expansion.anchorPoint) panel=\(expansion.panelFrame) handle=\(expansion.handleAttachmentPoint) clamped=\(expansion.wasClamped)"
            )
        }
        if hover.engine.phase != .editing {
            panel.allowsKey = false
        }
        if !panel.isVisible {
            panel.orderFrontRegardless()
        }
    }

    private var presentedPhase: PeekMemoCore.HoverPhase {
        if hover.engine.phase == .editing { return .editing }
        if hover.engine.phase == .pinned { return shellExpanded ? .pinned : .collapsed }
        return shellExpanded ? .expanded : .collapsed
    }

    private func refreshPresentedContent() {
        guard let anchor = anchorPlacement else { return }
        installContent(
            edge: anchor.edge,
            isNotchCloak: anchor.isNotchCloak,
            phase: presentedPhase,
            notchOccludedHeight: notchOccludedHeight(for: anchor)
        )
        hostView.dragHandleRect = dragHandleRect(
            in: hostView.bounds,
            edge: anchor.edge,
            expanded: shellExpanded
        )
    }

    private func finishFrameAnimation() {
        hostView.dragHandleRect = dragHandleRect(
            in: hostView.bounds,
            edge: anchorPlacement?.edge ?? .right,
            expanded: shellExpanded
        )
        hostView.installTrackingArea()
        evaluatePointer()
    }

    private func displayedPlacement(anchor: PanelPlacement, expanded: Bool) -> PanelPlacement {
        guard expanded, let screen = screenForAnchor(anchor) else {
            return anchor
        }
        let layout = ExpansionGeometry.layout(
            anchor: EdgeAnchor.from(anchor.stored),
            screen: screen,
            panelSize: previewSize,
            stackLength: positionManager.stackLength
        )
        currentExpansion = layout
        var expanded = anchor
        expanded.frame = layout.panelFrame
        return expanded
    }

    private func installContent(
        edge: ScreenEdge,
        isNotchCloak: Bool,
        phase: PeekMemoCore.HoverPhase,
        notchOccludedHeight: CGFloat
    ) {
        let root = PeekRootView(
            edge: edge,
            isNotchCloak: isNotchCloak,
            phase: phase,
            accent: .accent,
            showHitRegions: DebugFlags.showHitRegions,
            showInteractionRegions: DebugFlags.showInteractionRegions,
            notchOccludedHeight: notchOccludedHeight,
            contentOpacity: contentOpacity,
            appState: appState,
            onBeginEdit: { [weak self] in self?.hover.enterEditing() },
            onEndEdit: { [weak self] in self?.hover.exitEditing() },
            onInteractionBegan: { [weak self] in self?.beginTemporaryInteraction() },
            onInteractionEnded: { [weak self] in self?.endTemporaryInteraction() },
            onEditorFrameChange: { [weak self] rect in
                self?.editorScreenRect = rect
                self?.publishInteractionLog(at: NSEvent.mouseLocation)
            },
            handleOffsetInsidePanel: currentExpansion?.handleOffsetInsidePanel ?? 0,
            stackLength: positionManager.stackLength
        )
        if let hostingView {
            hostingView.rootView = root
            hostingView.frame = hostView.bounds
            return
        }
        let hosting = NSHostingView(rootView: root)
        hosting.sizingOptions = []
        hosting.clipsToBounds = false
        hosting.translatesAutoresizingMaskIntoConstraints = true
        hosting.autoresizingMask = [.width, .height] as NSView.AutoresizingMask
        hosting.frame = hostView.bounds
        hostView.addSubview(hosting, positioned: .below, relativeTo: nil)
        hostView.clipsToBounds = false
        hostingView = hosting
    }

    private func dragHandleRect(in bounds: CGRect, edge: ScreenEdge, expanded: Bool) -> CGRect? {
        guard expanded else { return nil }
        let occluded = (anchorPlacement?.isNotchCloak == true)
            ? (notchOccludedHeight(for: anchorPlacement!))
            : 0
        return DragHandleGeometry.rect(
            in: bounds,
            edge: edge,
            isNotchCloak: anchorPlacement?.isNotchCloak == true,
            notchOccludedHeight: occluded,
            handleOffsetInsidePanel: currentExpansion?.handleOffsetInsidePanel ?? bounds.height / 2,
            stackLength: positionManager.stackLength
        )
    }

    private func pointerHits(at point: CGPoint) -> HoverPointerHits {
        let edge = anchorPlacement?.frame ?? .null
        let panelFrame: CGRect? = shellExpanded ? panel.frame : nil
        let visibleEdge = shellExpanded ? edge : panel.frame
        return HoverRegion.hits(point, edge: visibleEdge, panel: panelFrame)
    }

    private func pointerIsInsideHoverRegion() -> Bool {
        pointerHits(at: NSEvent.mouseLocation).inside
    }

    private func evaluatePointer() {
        guard !hover.isDragging else { return }
        let point = NSEvent.mouseLocation
        let hits = pointerHits(at: point)
        if hits.inside {
            if !hover.engine.pointerInside || hover.isExitGracePending {
                hover.pointerEntered()
            }
        } else if hover.engine.pointerInside, !hover.isExitGracePending {
            hover.pointerExited()
        }
        publishInteractionLog(at: point, hits: hits)
    }

    private func beginTemporaryInteraction() {
        hover.beginInteraction()
        enterKeyMode()
    }

    private func endTemporaryInteraction() {
        hover.endInteraction()
        if !appState.isEditing, hover.engine.phase != .editing {
            exitKeyMode()
        }
        evaluatePointer()
    }

    private func startOutsideMonitor() {
        guard outsideMoveMonitor == nil else { return }
        outsideMoveMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    self?.evaluatePointer()
                }
            }
        }
    }

    private func stopOutsideMonitor() {
        if let outsideMoveMonitor {
            NSEvent.removeMonitor(outsideMoveMonitor)
            self.outsideMoveMonitor = nil
        }
    }

    private func screenForAnchor(_ placement: PanelPlacement) -> ScreenGeometry? {
        let screens = ScreenManager.allSnapshots()
        return screens.first(where: { $0.identifier == placement.displayIdentifier })
            ?? ScreenManager.mainSnapshot()
    }

    private func screen(for point: CGPoint) -> ScreenGeometry? {
        ScreenMigration.screenContaining(point: point, screens: ScreenManager.allSnapshots())
            ?? ScreenManager.mainSnapshot()
    }

    private func enterKeyMode() {
        panel.allowsKey = true
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        publishInteractionLog(at: NSEvent.mouseLocation)
    }

    private func exitKeyMode() {
        panel.allowsKey = false
        if panel.firstResponder is NSTextView || panel.firstResponder is NSTextField {
            panel.makeFirstResponder(nil)
        }
        if panel.isKeyWindow {
            panel.resignKey()
        }
        panel.invalidateCursorRects(for: hostView)
        if let hostingView {
            panel.invalidateCursorRects(for: hostingView)
        }
        panel.orderFrontRegardless()
        publishInteractionLog(at: NSEvent.mouseLocation)
    }

    private func notchOccludedHeight(for placement: PanelPlacement) -> CGFloat {
        guard placement.isNotchCloak, let screen = screenForAnchor(placement) else { return 0 }
        return NotchGeometry.region(on: screen)?.frame.height ?? 0
    }

    private func probeNotchHit(at point: CGPoint) {
        #if DEBUG
        guard let anchor = anchorPlacement, anchor.isNotchCloak,
              let screen = screenForAnchor(anchor),
              let notch = NotchGeometry.region(on: screen)
        else { return }
        NotchHitProbe.record(point: point, notch: notch)
        #endif
    }

    private func refreshNotchSensor(anchor: PanelPlacement) {
        guard anchor.isNotchCloak, !shellExpanded, !hover.isDragging,
              let screen = screenForAnchor(anchor),
              let notch = NotchGeometry.region(on: screen)
        else {
            notchSensor.hide()
            return
        }
        notchSensor.show(notch: notch, useFallbackStrip: true)
    }

    private func logNotchFrames(requested: CGRect, anchor: PanelPlacement) {
        guard anchor.isNotchCloak else { return }
        let actual = panel.frame
        let contained: Bool
        if let screen = screenForAnchor(anchor), let notch = NotchGeometry.region(on: screen) {
            contained = NotchGeometry.isFullyContained(actual, in: notch.frame)
            print("[Notch] notchRect \(notch.frame)")
        } else {
            contained = false
        }
        print("[Notch] requested \(requested)")
        print("[Notch] actual    \(actual)")
        print("[Notch] AppKit constrained=\(requested != actual) containedInNotch=\(contained)")
        print("[Notch] activation \(notchSensor.mechanism)")
    }

    private func refreshNotchDebugOverlay() {
        #if DEBUG
        guard DebugFlags.showNotchGeometry,
              let anchor = anchorPlacement, anchor.isNotchCloak,
              let screen = screenForAnchor(anchor),
              let notch = NotchGeometry.region(on: screen)
        else {
            notchDebugOverlay.hide()
            return
        }
        notchDebugOverlay.show(notch: notch, anchor: anchor.frame, screen: screen)
        #else
        notchDebugOverlay.hide()
        #endif
    }

    private func publishInteractionLog(at point: CGPoint, hits: HoverPointerHits? = nil) {
        #if DEBUG
        let resolved = hits ?? pointerHits(at: point)
        let insideEditor = editorScreenRect?.contains(point) ?? false
        let key = InteractionLogKey(
            hoverState: hover.engine.phase,
            editingItemID: appState.editingItemID,
            isComposing: appState.isComposing,
            isKeyWindow: panel.isKeyWindow,
            allowsKey: panel.allowsKey,
            isPinned: hover.engine.isPinned,
            interactionHoldCount: hover.engine.interactionHoldCount,
            mouseInsideEdge: resolved.insideEdge,
            mouseInsidePanel: resolved.insidePanel,
            insideEditor: insideEditor
        )
        guard key != lastInteractionLog else { return }
        lastInteractionLog = key
        let editing = appState.editingItemID?.uuidString ?? "nil"
        print(
            "[Hover] mouse=(\(point.x),\(point.y)) insideEdge=\(resolved.insideEdge) insidePanel=\(resolved.insidePanel) insideEditor=\(insideEditor) state=\(hover.engine.phase.rawValue)"
        )
        print(
            "[Interaction] hoverState=\(hover.engine.phase.rawValue) editingItemID=\(editing) isKeyWindow=\(panel.isKeyWindow) allowsKey=\(panel.allowsKey) isPinned=\(hover.engine.isPinned) interactionHoldCount=\(hover.engine.interactionHoldCount) mouseInsideEdge=\(resolved.insideEdge) mouseInsidePanel=\(resolved.insidePanel)"
        )
        #endif
    }

    private func observeScreenChanges() {
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.reposition()
            }
        }
    }
}
