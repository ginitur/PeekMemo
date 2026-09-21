import AppKit
import PeekMemoCore

@MainActor
struct PanelPositionManager {
    var stackLength: CGFloat = LayoutMetrics.defaultStackLength

    func collapsedPlacement(
        edge: ScreenEdge,
        offset: CGFloat,
        screen: ScreenGeometry
    ) -> PanelPlacement {
        EdgeGeometry.collapsedPlacement(
            screen: screen,
            edge: edge,
            offset: offset,
            stackLength: stackLength
        )
    }

    func apply(_ placement: PanelPlacement, to panel: NSPanel) {
        panel.setFrame(placement.frame, display: true)
    }
}
