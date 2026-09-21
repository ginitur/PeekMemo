import AppKit

/// Minimal accessory-app status item. Full menu lands in Phase 9.
@MainActor
final class StatusItemController {
    private let item: NSStatusItem

    init() {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(
                systemSymbolName: "note.text",
                accessibilityDescription: "PeekMemo"
            )
            button.image?.isTemplate = true
            button.toolTip = "PeekMemo"
        }

        let menu = NSMenu()
        menu.addItem(Self.headerItem())
        menu.addItem(.separator())
        let quit = NSMenuItem(
            title: "Quit PeekMemo",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quit)
        item.menu = menu
    }

    private static func headerItem() -> NSMenuItem {
        let item = NSMenuItem(title: "PeekMemo", action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }
}
