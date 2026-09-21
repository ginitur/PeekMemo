import AppKit
import PeekMemoCore
import SwiftUI

/// Owns the floating edge panel. Phase 1 shows a collapsed tab on the right edge.
@MainActor
final class PanelController {
    private let panel = PeekPanel()
    private let positionManager = PanelPositionManager()
    private var hostingView: NSHostingView<CollapsedEdgeView>?
    private var currentPlacement: PanelPlacement?
    private var screenChangeObserver: NSObjectProtocol?

    init() {
        panel.contentView = NSView(frame: .zero)
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
        observeScreenChanges()
    }

    func showCollapsed(edge: ScreenEdge, offset: CGFloat) {
        guard let screen = ScreenManager.mainSnapshot() else {
            return
        }
        let placement = positionManager.collapsedPlacement(
            edge: edge,
            offset: offset,
            screen: screen
        )
        apply(placement)
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    func reposition() {
        guard let current = currentPlacement else {
            showCollapsed(edge: .right, offset: AppSettings.default.edgeOffset)
            return
        }
        let screens = ScreenManager.allSnapshots()
        let mainID = ScreenManager.mainSnapshot()?.identifier ?? screens.first?.identifier ?? current.displayIdentifier
        let resolved = ScreenMigration.resolve(
            saved: current.stored,
            screens: screens,
            mainScreenID: mainID
        )
        guard let screen = resolved.screen else {
            hide()
            return
        }
        let placement = EdgeGeometry.placement(
            from: resolved.placement,
            screen: screen,
            stackLength: positionManager.stackLength
        )
        apply(placement)
    }

    private func apply(_ placement: PanelPlacement) {
        currentPlacement = placement
        positionManager.apply(placement, to: panel)
        installContent(edge: placement.edge)
    }

    private func installContent(edge: ScreenEdge) {
        let root = CollapsedEdgeView(edge: edge)
        if let hostingView {
            hostingView.rootView = root
            return
        }
        let hosting = NSHostingView(rootView: root)
        hosting.translatesAutoresizingMaskIntoConstraints = true
        hosting.autoresizingMask = [.width, .height]
        hosting.frame = panel.contentView?.bounds ?? placementFallbackBounds
        panel.contentView = hosting
        hostingView = hosting
    }

    private var placementFallbackBounds: NSRect {
        NSRect(
            origin: .zero,
            size: EdgeGeometry.collapsedWindowSize(edge: .right, stackLength: LayoutMetrics.defaultStackLength)
        )
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
