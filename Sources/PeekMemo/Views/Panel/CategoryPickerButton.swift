import AppKit
import PeekMemoCore
import SwiftUI

struct CategoryPickerButton: NSViewRepresentable {
    var label: String
    var categories: [PeekMemoCore.Category]
    var onSelectAll: () -> Void
    var onSelect: (UUID) -> Void
    var onNew: () -> Void
    var onWillOpen: () -> Void
    var onDidClose: () -> Void

    func makeNSView(context: Context) -> CategoryPickerNSView {
        let view = CategoryPickerNSView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ view: CategoryPickerNSView, context: Context) {
        context.coordinator.label = label
        context.coordinator.categories = categories
        context.coordinator.onSelectAll = onSelectAll
        context.coordinator.onSelect = onSelect
        context.coordinator.onNew = onNew
        context.coordinator.onWillOpen = onWillOpen
        context.coordinator.onDidClose = onDidClose
        view.coordinator = context.coordinator
        view.needsDisplay = true
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject {
        var label = "All"
        var categories: [PeekMemoCore.Category] = []
        var onSelectAll: () -> Void = {}
        var onSelect: (UUID) -> Void = { _ in }
        var onNew: () -> Void = {}
        var onWillOpen: () -> Void = {}
        var onDidClose: () -> Void = {}

        @objc func chooseAll(_ sender: NSMenuItem) { onSelectAll() }
        @objc func chooseCategory(_ sender: NSMenuItem) {
            if let raw = sender.representedObject as? String, let id = UUID(uuidString: raw) {
                onSelect(id)
            }
        }
        @objc func chooseNew(_ sender: NSMenuItem) { onNew() }
    }
}

final class CategoryPickerNSView: NSView {
    weak var coordinator: CategoryPickerButton.Coordinator?

    override var isFlipped: Bool { true }

    override var intrinsicContentSize: NSSize {
        let text = (coordinator?.label ?? "All") + " ▾"
        let size = text.size(withAttributes: Self.attributes)
        return NSSize(width: ceil(size.width) + 16, height: LayoutMetrics.categoryHitHeight)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        return bounds.contains(local) ? self : nil
    }

    override var needsPanelToBecomeKey: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        let text = (coordinator?.label ?? "All") + " ▾"
        let size = text.size(withAttributes: Self.attributes)
        text.draw(
            at: CGPoint(x: 8, y: (bounds.height - size.height) / 2),
            withAttributes: Self.attributes
        )
    }

    override func mouseDown(with event: NSEvent) {
        guard let coordinator else { return }
        coordinator.onWillOpen()
        let menu = NSMenu()
        menu.autoenablesItems = false
        let all = NSMenuItem(title: "All", action: #selector(CategoryPickerButton.Coordinator.chooseAll(_:)), keyEquivalent: "")
        all.target = coordinator
        menu.addItem(all)
        menu.addItem(.separator())
        for category in coordinator.categories {
            let item = NSMenuItem(title: category.name, action: #selector(CategoryPickerButton.Coordinator.chooseCategory(_:)), keyEquivalent: "")
            item.target = coordinator
            item.representedObject = category.id.uuidString
            menu.addItem(item)
        }
        menu.addItem(.separator())
        let newItem = NSMenuItem(title: "+ New Category", action: #selector(CategoryPickerButton.Coordinator.chooseNew(_:)), keyEquivalent: "")
        newItem.target = coordinator
        menu.addItem(newItem)
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: bounds.height), in: self)
        coordinator.onDidClose()
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    private static let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 11, weight: .medium),
        .foregroundColor: NSColor.secondaryLabelColor,
    ]
}
