import AppKit

/// Accessory-app status item. Expanded in Phase 9.
@MainActor
final class StatusItemController {
    private let item: NSStatusItem
    private let onShow: () -> Void
    private let onHide: () -> Void
    private let onReset: () -> Void
    private let onToggleHitRegions: () -> Void
    private let onToggleNotchGeometry: () -> Void
    private let onMoveToNotch: () -> Void
    private let onToggleAnchorGeometry: () -> Void
    private let onToggleInteractionRegions: () -> Void

    init(
        onShow: @escaping () -> Void,
        onHide: @escaping () -> Void,
        onReset: @escaping () -> Void,
        onToggleHitRegions: @escaping () -> Void = {},
        onToggleNotchGeometry: @escaping () -> Void = {},
        onMoveToNotch: @escaping () -> Void = {},
        onToggleAnchorGeometry: @escaping () -> Void = {},
        onToggleInteractionRegions: @escaping () -> Void = {}
    ) {
        self.onShow = onShow
        self.onHide = onHide
        self.onReset = onReset
        self.onToggleHitRegions = onToggleHitRegions
        self.onToggleNotchGeometry = onToggleNotchGeometry
        self.onMoveToNotch = onMoveToNotch
        self.onToggleAnchorGeometry = onToggleAnchorGeometry
        self.onToggleInteractionRegions = onToggleInteractionRegions
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(
                systemSymbolName: "note.text",
                accessibilityDescription: "PeekMemo"
            )
            button.image?.isTemplate = true
            button.toolTip = "PeekMemo"
        }
        item.menu = makeMenu()
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        let header = NSMenuItem(title: "PeekMemo", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        let show = NSMenuItem(title: "Show PeekMemo", action: #selector(showPanel), keyEquivalent: "")
        show.target = self
        menu.addItem(show)

        let hide = NSMenuItem(title: "Hide PeekMemo", action: #selector(hidePanel), keyEquivalent: "")
        hide.target = self
        menu.addItem(hide)

        let reset = NSMenuItem(title: "Reset Position", action: #selector(resetPosition), keyEquivalent: "")
        reset.target = self
        menu.addItem(reset)

        #if DEBUG
        menu.addItem(.separator())
        let hits = NSMenuItem(
            title: "Show Hit Regions",
            action: #selector(toggleHitRegions),
            keyEquivalent: ""
        )
        hits.target = self
        hits.state = DebugFlags.showHitRegions ? .on : .off
        menu.addItem(hits)

        let notch = NSMenuItem(
            title: "Show Notch Geometry",
            action: #selector(toggleNotchGeometry),
            keyEquivalent: ""
        )
        notch.target = self
        notch.state = DebugFlags.showNotchGeometry ? .on : .off
        menu.addItem(notch)

        let cloak = NSMenuItem(
            title: "Move to Notch Cloak",
            action: #selector(moveToNotch),
            keyEquivalent: ""
        )
        cloak.target = self
        menu.addItem(cloak)

        let anchor = NSMenuItem(
            title: "Show Anchor Geometry",
            action: #selector(toggleAnchorGeometry),
            keyEquivalent: ""
        )
        anchor.target = self
        anchor.state = DebugFlags.showAnchorGeometry ? .on : .off
        menu.addItem(anchor)

        let experimental = NSMenuItem(
            title: "Experimental Top / Notch",
            action: #selector(toggleExperimentalTop),
            keyEquivalent: ""
        )
        experimental.target = self
        experimental.state = DebugFlags.experimentalTopEdge ? .on : .off
        menu.addItem(experimental)

        let regions = NSMenuItem(
            title: "Show Interaction Regions",
            action: #selector(toggleInteractionRegions),
            keyEquivalent: ""
        )
        regions.target = self
        regions.state = DebugFlags.showInteractionRegions ? .on : .off
        menu.addItem(regions)
        #endif

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "Quit PeekMemo",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
        return menu
    }

    @objc private func showPanel() {
        onShow()
    }

    @objc private func hidePanel() {
        onHide()
    }

    @objc private func resetPosition() {
        onReset()
    }

    #if DEBUG
    @objc private func toggleHitRegions() {
        onToggleHitRegions()
        item.menu = makeMenu()
    }

    @objc private func toggleNotchGeometry() {
        onToggleNotchGeometry()
        item.menu = makeMenu()
    }

    @objc private func moveToNotch() {
        onMoveToNotch()
    }

    @objc private func toggleAnchorGeometry() {
        onToggleAnchorGeometry()
        item.menu = makeMenu()
    }

    @objc private func toggleExperimentalTop() {
        DebugFlags.experimentalTopEdge.toggle()
        item.menu = makeMenu()
    }

    @objc private func toggleInteractionRegions() {
        onToggleInteractionRegions()
        item.menu = makeMenu()
    }
    #endif
}
