import AppKit
import PeekMemoCore
import SwiftUI

/// Owns the floating edge panel. Dragging snaps to Left / Right / Top / Bottom.
@MainActor
final class PanelController {
    private let panel = PeekPanel()
    private let positionManager = PanelPositionManager()
    private let hostView = EdgeHostView()
    private var hostingView: NSHostingView<CollapsedEdgeView>?
    private var currentPlacement: PanelPlacement?
    private var screenChangeObserver: (any NSObjectProtocol)?

    init() {
        hostView.wantsLayer = true
        hostView.layer?.backgroundColor = NSColor.clear.cgColor
        hostView.onDrag = { [weak self] point in
            self?.handleDrag(at: point)
        }
        hostView.onDragEnded = { [weak self] point in
            self?.handleDragEnded(at: point)
        }
        panel.contentView = hostView
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
        apply(
            EdgeGeometry.placement(
                from: stored,
                screen: screen,
                stackLength: positionManager.stackLength
            )
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
        let stored = DisplayPlacement(
            displayIdentifier: screen.identifier,
            edge: .right,
            offset: AppSettings.default.edgeOffset
        )
        PlacementStore.upsert(stored)
        apply(
            EdgeGeometry.placement(
                from: stored,
                screen: screen,
                stackLength: positionManager.stackLength
            )
        )
        panel.orderFrontRegardless()
    }

    func reposition() {
        let screens = ScreenManager.allSnapshots()
        guard let main = ScreenManager.mainSnapshot() ?? screens.first else {
            hide()
            return
        }
        let saved = currentPlacement?.stored
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
        apply(
            EdgeGeometry.placement(
                from: resolved.placement,
                screen: screen,
                stackLength: positionManager.stackLength
            )
        )
        PlacementStore.upsert(resolved.placement)
    }

    private func handleDrag(at point: CGPoint) {
        guard let screen = screen(for: point) else { return }
        let grab = currentPlacement?.frame.size
            ?? EdgeGeometry.collapsedWindowSize(edge: .right, stackLength: positionManager.stackLength)
        let placement = EdgeGeometry.draggingPlacement(
            pointer: point,
            screen: screen,
            stackLength: positionManager.stackLength,
            grabSize: grab
        )
        apply(placement, persist: false)
    }

    private func handleDragEnded(at point: CGPoint) {
        guard let screen = screen(for: point) else { return }
        let placement = EdgeGeometry.committedPlacement(
            pointer: point,
            screen: screen,
            stackLength: positionManager.stackLength
        )
        apply(placement, persist: true)
    }

    private func apply(_ placement: PanelPlacement, persist: Bool = false) {
        let edgeChanged = currentPlacement?.edge != placement.edge
        currentPlacement = placement
        positionManager.apply(placement, to: panel)
        if edgeChanged || hostingView == nil {
            installContent(edge: placement.edge)
        }
        if persist {
            PlacementStore.upsert(placement.stored)
        }
    }

    private func installContent(edge: ScreenEdge) {
        let root = CollapsedEdgeView(edge: edge)
        if let hostingView {
            hostingView.rootView = root
            hostingView.frame = hostView.bounds
            return
        }
        let hosting = NSHostingView(rootView: root)
        hosting.translatesAutoresizingMaskIntoConstraints = true
        hosting.autoresizingMask = [.width, .height]
        hosting.frame = hostView.bounds
        // SwiftUI view is visual only; mouse events stay on EdgeHostView.
        hosting.isHidden = false
        hostView.addSubview(hosting, positioned: .below, relativeTo: nil)
        hostingView = hosting
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
