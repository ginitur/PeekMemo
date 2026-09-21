import AppKit
import PeekMemoCore

/// DEBUG overlay drawn in the visible area just below the housing, since pixels inside the notch are occluded.
@MainActor
final class NotchDebugOverlay {
    private let panel = PeekPanel()
    private let label = NSTextField(wrappingLabelWithString: "")

    init() {
        panel.level = .statusBar
        panel.ignoresMouseEvents = true
        panel.hasShadow = false
        label.font = .monospacedSystemFont(ofSize: 10, weight: .medium)
        label.textColor = .white
        label.backgroundColor = NSColor.systemOrange.withAlphaComponent(0.85)
        label.drawsBackground = true
        label.isBordered = false
        panel.contentView = label
    }

    func show(notch: NotchRegion, anchor: CGRect, screen: ScreenGeometry) {
        let text = """
        notchRect  minX=\(fmt(notch.frame.minX)) maxX=\(fmt(notch.frame.maxX)) minY=\(fmt(notch.frame.minY)) maxY=\(fmt(notch.frame.maxY))
        activation \(fmt(LayoutMetrics.notchActivationExtension))pt below minY
        anchor     \(fmt(anchor.minX)),\(fmt(anchor.minY)) \(fmt(anchor.width))×\(fmt(anchor.height))
        center     \(fmt(notch.frame.midX)), \(fmt(notch.frame.midY)) inside notchRect
        """
        label.stringValue = text
        let size = label.intrinsicContentSize
        let width = min(max(size.width + 16, notch.frame.width), screen.visibleFrame.width)
        let height = max(size.height + 12, 64)
        let frame = CGRect(
            x: notch.frame.midX - width / 2,
            y: notch.frame.minY - height - 8,
            width: width,
            height: height
        )
        panel.setFrame(frame, display: true)
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    private func fmt(_ value: CGFloat) -> String {
        String(format: "%.1f", value)
    }
}
