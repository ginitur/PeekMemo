import AppKit
import PeekMemoCore

/// Invisible hit surface for Notch Cloak. Never draws a handle, line, or background.
@MainActor
final class NotchActivationSensor {
    var onEnter: (() -> Void)?
    var onExit: (() -> Void)?

    private let panel = PeekPanel()
    private let host = TrackingView()
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var notchRect: CGRect = .null
    private var inside = false
    private(set) var mechanism = "uninitialized"

    init() {
        panel.allowNotchPlacement = true
        panel.alphaValue = 0
        panel.hasShadow = false
        panel.ignoresMouseEvents = false
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue - 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        host.onEnter = { [weak self] in self?.handleEnter(source: "sensor-window") }
        host.onExit = { [weak self] in self?.handleExit() }
        panel.contentView = host
    }

    func show(notch: NotchRegion, useFallbackStrip: Bool) {
        notchRect = notch.frame
        let strip = NotchGeometry.activationExtensionRect(
            for: notch,
            activationExtension: LayoutMetrics.notchActivationExtension
        )
        // Prefer the housing itself; keep an invisible 3pt strip as fallback only.
        let frame = useFallbackStrip && !strip.isNull ? strip : notch.frame
        panel.allowNotchPlacement = true
        panel.setFrame(frame, display: true)
        panel.orderFrontRegardless()
        print("[NotchSensor] requested \(frame) actual \(panel.frame) fallback=\(useFallbackStrip)")
        startMonitors()
        mechanism = useFallbackStrip
            ? "fallback \(LayoutMetrics.notchActivationExtension)pt strip + mouse-location monitor"
            : "notchRect window + mouse-location monitor"
    }

    func hide() {
        stopMonitors()
        panel.orderOut(nil)
        inside = false
    }

    private func startMonitors() {
        stopMonitors()
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] event in
            self?.evaluate(NSEvent.mouseLocation, source: "local-monitor")
            return event
        }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] _ in
            self?.evaluate(NSEvent.mouseLocation, source: "global-monitor")
        }
    }

    private func stopMonitors() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
    }

    private func evaluate(_ point: CGPoint, source: String) {
        let hit = notchRect.contains(point)
            || NotchGeometry.hitZone(
                of: point,
                notch: NotchRegion(frame: notchRect)
            ) == .activationExtension
        if hit, !inside {
            handleEnter(source: source)
        } else if !hit, inside {
            handleExit()
        }
    }

    private func handleEnter(source: String) {
        guard !inside else { return }
        inside = true
        print("[NotchSensor] enter via \(source)")
        onEnter?()
    }

    private func handleExit() {
        guard inside else { return }
        inside = false
        print("[NotchSensor] exit")
        onExit?()
    }
}

private final class TrackingView: NSView {
    var onEnter: (() -> Void)?
    var onExit: (() -> Void)?

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(
            NSTrackingArea(
                rect: bounds,
                options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                owner: self,
                userInfo: nil
            )
        )
    }

    override func mouseEntered(with event: NSEvent) { onEnter?() }
    override func mouseExited(with event: NSEvent) { onExit?() }
}
