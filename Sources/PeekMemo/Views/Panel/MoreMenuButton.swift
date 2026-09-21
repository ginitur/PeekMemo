import AppKit
import PeekMemoCore
import SwiftUI

/// AppKit `NSMenu.popUp` so More opens on the first click of a nonactivating panel
/// and is not clipped by the hosting view.
struct MoreMenuButton: NSViewRepresentable {
    var lists: [UserList]
    var onSelect: (NavigationID) -> Void
    var onNewList: () -> Void
    var onWillOpen: () -> Void
    var onDidClose: () -> Void

    func makeNSView(context: Context) -> MoreMenuNSView {
        let view = MoreMenuNSView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ view: MoreMenuNSView, context: Context) {
        context.coordinator.lists = lists
        context.coordinator.onSelect = onSelect
        context.coordinator.onNewList = onNewList
        context.coordinator.onWillOpen = onWillOpen
        context.coordinator.onDidClose = onDidClose
        view.coordinator = context.coordinator
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject {
        var lists: [UserList] = []
        var onSelect: (NavigationID) -> Void = { _ in }
        var onNewList: () -> Void = {}
        var onWillOpen: () -> Void = {}
        var onDidClose: () -> Void = {}
        var selectedID: NSNumber?

        @objc func chooseList(_ sender: NSMenuItem) {
            let id = UUID(uuidString: sender.representedObject as? String ?? "")
            if let id {
                onSelect(.list(id))
            }
        }

        @objc func chooseCompleted(_ sender: NSMenuItem) {
            onSelect(.smart(.completed))
        }

        @objc func chooseNew(_ sender: NSMenuItem) {
            onNewList()
        }
    }
}

final class MoreMenuNSView: NSView {
    weak var coordinator: MoreMenuButton.Coordinator?

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        let text = "More"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.secondaryLabelColor,
        ]
        let size = text.size(withAttributes: attrs)
        text.draw(
            at: CGPoint(x: 0, y: (bounds.height - size.height) / 2),
            withAttributes: attrs
        )
    }

    override func mouseDown(with event: NSEvent) {
        guard let coordinator else { return }
        coordinator.onWillOpen()
        let menu = NSMenu()
        menu.autoenablesItems = false
        let completed = NSMenuItem(title: "Completed", action: #selector(MoreMenuButton.Coordinator.chooseCompleted(_:)), keyEquivalent: "")
        completed.target = coordinator
        menu.addItem(completed)
        menu.addItem(.separator())
        for list in coordinator.lists {
            let item = NSMenuItem(title: list.name, action: #selector(MoreMenuButton.Coordinator.chooseList(_:)), keyEquivalent: "")
            item.target = coordinator
            item.representedObject = list.id.uuidString
            menu.addItem(item)
        }
        menu.addItem(.separator())
        let newItem = NSMenuItem(title: "New List", action: #selector(MoreMenuButton.Coordinator.chooseNew(_:)), keyEquivalent: "")
        newItem.target = coordinator
        menu.addItem(newItem)
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: bounds.height), in: self)
        coordinator.onDidClose()
        needsDisplay = true
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
