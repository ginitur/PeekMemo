import AppKit
import PeekMemoCore

@MainActor
struct PanelPositionManager {
    var stackLength: CGFloat = LayoutMetrics.defaultStackLength
    private let animator = WindowFrameAnimator()

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

    func apply(
        _ placement: PanelPlacement,
        to panel: NSPanel,
        animated: Bool = false,
        expanding: Bool = true,
        duration: TimeInterval = LayoutMetrics.expandDuration
    ) {
        if animated {
            animator.animate(
                panel: panel,
                to: placement.frame,
                duration: duration,
                expanding: expanding
            )
        } else {
            animator.snap(panel, to: placement.frame)
        }
    }
}
