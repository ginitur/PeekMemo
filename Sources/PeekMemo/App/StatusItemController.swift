import AppKit

/// Accessory-app status item. Expanded in Phase 9.
@MainActor
final class StatusItemController {
    private let item: NSStatusItem
    private let onShow: () -> Void
    private let onHide: () -> Void
    private let onReset: () -> Void
    private let onToggleHitRegions: () -> Void

    init(
        onShow: @escaping () -> Void,
        onHide: @escaping () -> Void,
        onReset: @escaping () -> Void,
        onToggleHitRegions: @escaping () -> Void = {}
    ) {
        self.onShow = onShow
        self.onHide = onHide
        self.onReset = onReset
        self.onToggleHitRegions = onToggleHitRegions
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
    #endif
}
