import AppKit
import SwiftUI

extension NSToolbarItem.Identifier {
    static let peekGeneral = NSToolbarItem.Identifier("peekmemo.settings.general")
    static let peekAppearance = NSToolbarItem.Identifier("peekmemo.settings.appearance")
    static let peekBehavior = NSToolbarItem.Identifier("peekmemo.settings.behavior")
}

/// Native Settings window. The floating panel stays nonactivating; this window is a normal window.
@MainActor
final class PreferencesWindowController: NSObject, NSToolbarDelegate {
    private let model: PreferencesModel
    private let window: NSWindow

    init(model: PreferencesModel) {
        self.model = model
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        super.init()
        window.title = "PeekMemo Settings"
        window.minSize = NSSize(width: 480, height: 420)
        window.isReleasedWhenClosed = false
        window.toolbarStyle = .preference
        let toolbar = NSToolbar(identifier: "PeekMemo.Settings")
        toolbar.delegate = self
        toolbar.allowsUserCustomization = false
        toolbar.displayMode = .iconAndLabel
        toolbar.selectedItemIdentifier = .peekGeneral
        window.toolbar = toolbar
        let hosting = NSHostingView(rootView: PreferencesView(model: model))
        hosting.sizingOptions = []
        window.contentView = hosting
        window.center()
        applyTheme()
    }

    func show() {
        model.refreshLaunchAtLoginFromSystem()
        applyTheme()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    func applyTheme() {
        window.appearance = model.windowAppearance
    }

    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        switch itemIdentifier {
        case .peekGeneral:
            item.label = "General"
            item.image = symbol("gearshape")
        case .peekAppearance:
            item.label = "Appearance"
            item.image = symbol("paintbrush")
        case .peekBehavior:
            item.label = "Behavior"
            item.image = symbol("timer")
        default:
            return nil
        }
        item.target = self
        item.action = #selector(selectPage(_:))
        return item
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.peekGeneral, .peekAppearance, .peekBehavior]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    @objc private func selectPage(_ sender: NSToolbarItem) {
        switch sender.itemIdentifier {
        case .peekGeneral: model.page = .general
        case .peekAppearance: model.page = .appearance
        case .peekBehavior: model.page = .behavior
        default: return
        }
        window.toolbar?.selectedItemIdentifier = sender.itemIdentifier
    }

    private func symbol(_ name: String) -> NSImage? {
        NSImage(systemSymbolName: name, accessibilityDescription: nil)
    }
}
