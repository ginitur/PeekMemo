import AppKit
import PeekMemoCore

/// Sole owner of NSPanel frame motion. Views must not resize the window.
@MainActor
final class WindowFrameAnimator {
    func animate(
        panel: NSPanel,
        to frame: CGRect,
        duration: TimeInterval,
        expanding: Bool
    ) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = expanding
                ? CAMediaTimingFunction(controlPoints: 0.16, 0.84, 0.32, 1)
                : CAMediaTimingFunction(controlPoints: 0.4, 0, 0.2, 1)
            context.allowsImplicitAnimation = true
            panel.animator().setFrame(frame, display: true)
        }
    }

    func snap(_ panel: NSPanel, to frame: CGRect) {
        panel.setFrame(frame, display: true)
    }
}
