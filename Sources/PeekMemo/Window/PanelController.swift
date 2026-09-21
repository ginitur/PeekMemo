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

    private var previewSize: CGSize {
        CGSize(width: LayoutMetrics.previewPanelWidth, height: LayoutMetrics.previewPanelHeight)
    }

    init() {
        hostView.wantsLayer = true
        hostView.layer?.backgroundColor = NSColor.clear.cgColor
        hostView.onDragBegan = { [weak self] in
            self?.hover.beginDrag()
            self?.syncChrome(animated: false)
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
            self?.hover.pointerEntered()
        }
        hostView.onPointerExited = { [weak self] in
            self?.hover.pointerExited()
        }
        hover.regionContainsPointer = { [weak self] in
            self?.pointerIsInsideHoverRegion() ?? false
        }
        hover.onOutput = { [weak self] output in
            self?.handleHoverOutput(output)
        }
        panel.contentView = hostView
        panel.allowsKey = false
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
        panel.orderOut(nil)
    }

    func resetPosition() {
        guard let screen = ScreenManager.mainSnapshot() else {
            return
        }
        hover.forceCollapse()
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
        case .expand, .collapse, .beginEditing:
            syncChrome(animated: !hover.isDragging)
        case .none, .scheduleOpen, .scheduleClose, .cancelTimers:
            break
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

    private func syncChrome(animated: Bool) {
        guard let anchor = anchorPlacement else { return }
        let phase = hover.engine.phase
        let framePlacement = displayedPlacement(anchor: anchor, phase: phase)
        positionManager.apply(framePlacement, to: panel, animated: animated)
        installContent(
            edge: anchor.edge,
            isNotchCloak: anchor.isNotchCloak,
            phase: phase
        )
        hostView.dragHandleRect = dragHandleRect(
            in: hostView.bounds,
            edge: anchor.edge,
            expanded: phase.isVisuallyExpanded
        )
        panel.allowsKey = false
        if !panel.isVisible {
            panel.orderFrontRegardless()
        }
        if animated {
            DispatchQueue.main.asyncAfter(deadline: .now() + LayoutMetrics.panelAnimationDuration) { [weak self] in
                guard let self, let anchor = self.anchorPlacement else { return }
                self.hostView.dragHandleRect = self.dragHandleRect(
                    in: self.hostView.bounds,
                    edge: anchor.edge,
                    expanded: self.hover.engine.phase.isVisuallyExpanded
                )
            }
        }
    }

    private func displayedPlacement(anchor: PanelPlacement, phase: PeekMemoCore.HoverPhase) -> PanelPlacement {
        guard phase.isVisuallyExpanded, let screen = screenForAnchor(anchor) else {
            return anchor
        }
        var expanded = anchor
        expanded.frame = EdgeGeometry.expandedFrame(
            collapsed: anchor,
            screen: screen,
            panelSize: previewSize
        )
        return expanded
    }

    private func installContent(edge: ScreenEdge, isNotchCloak: Bool, phase: PeekMemoCore.HoverPhase) {
        let root = PeekRootView(
            edge: edge,
            isNotchCloak: isNotchCloak,
            phase: phase,
            accent: .accent,
            showHitRegions: DebugFlags.showHitRegions
        )
        if let hostingView {
            hostingView.rootView = root
            hostingView.frame = hostView.bounds
            return
        }
        let hosting = NSHostingView(rootView: root)
        hosting.translatesAutoresizingMaskIntoConstraints = true
        hosting.autoresizingMask = [.width, .height] as NSView.AutoresizingMask
        hosting.frame = hostView.bounds
        hostView.addSubview(hosting, positioned: .below, relativeTo: nil)
        hostingView = hosting
    }

    private func dragHandleRect(in bounds: CGRect, edge: ScreenEdge, expanded: Bool) -> CGRect? {
        guard expanded else { return nil }
        let thickness = LayoutMetrics.hoverHitThickness
        switch edge {
        case .right:
            return CGRect(x: bounds.width - thickness, y: 0, width: thickness, height: bounds.height)
        case .left:
            return CGRect(x: 0, y: 0, width: thickness, height: bounds.height)
        case .top:
            return CGRect(x: 0, y: bounds.height - thickness, width: bounds.width, height: thickness)
        case .bottom:
            return CGRect(x: 0, y: 0, width: bounds.width, height: thickness)
        }
    }

    private func pointerIsInsideHoverRegion() -> Bool {
        guard let anchor = anchorPlacement else { return false }
        let phase = hover.engine.phase
        let collapsed = anchor.frame
        let expanded: CGRect
        if let screen = screenForAnchor(anchor) {
            expanded = EdgeGeometry.expandedFrame(
                collapsed: anchor,
                screen: screen,
                panelSize: previewSize
            )
        } else {
            expanded = collapsed
        }
        return HoverRegion.contains(
            NSEvent.mouseLocation,
            collapsed: collapsed,
            expanded: expanded,
            phase: phase
        )
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
