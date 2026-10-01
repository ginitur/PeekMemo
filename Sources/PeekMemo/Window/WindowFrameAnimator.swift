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
            // Ease-out. Control points stay inside 0...1; the slight overshoot is the content spring.
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1, 0.3, 1)
            context.allowsImplicitAnimation = true
            panel.animator().setFrame(frame, display: true)
        }
    }

    func snap(_ panel: NSPanel, to frame: CGRect) {
        panel.setFrame(frame, display: true)
    }
}
