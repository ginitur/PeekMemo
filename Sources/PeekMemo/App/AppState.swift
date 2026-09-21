import Foundation
import Observation
import PeekMemoCore

/// In-memory prototype store. Lost on quit. Persistence is Phase 6.
@Observable
@MainActor
final class AppState {
    var lists: [UserList]
    var items: [MemoItem]
    var selectedListID: UUID
    var editingItemID: UUID?
    var composingParentID: UUID?
    var draftText: String = ""
    var isComposing: Bool = false
    var completedExpanded = false
    var pendingHideIDs: Set<UUID> = []

    var selectedList: UserList? {
        lists.first(where: { $0.id == selectedListID })
    }

    var openItems: [MemoItem] {
        TaskHierarchy.openRoots(in: items, listId: selectedListID)
    }

    var completedItems: [MemoItem] {
        TaskHierarchy.completedRoots(in: items, listId: selectedListID)
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    var isEditing: Bool {
        isComposing || editingItemID != nil
    }

    init() {
        let now = Date()
        let inbox = UserList(name: "Inbox", icon: "tray", color: .inbox, sortOrder: 0, createdAt: now, updatedAt: now)
        lists = [inbox]
        selectedListID = inbox.id
        let parent = MemoItem(listId: inbox.id, type: .task, title: "Prepare report", sortOrder: 0, createdAt: now, updatedAt: now)
        items = [
            parent,
            MemoItem(listId: inbox.id, parentId: parent.id, type: .task, title: "Collect data", isCompleted: true, completedAt: now, sortOrder: 0),
            MemoItem(listId: inbox.id, parentId: parent.id, type: .task, title: "Update charts", sortOrder: 1),
            MemoItem(listId: inbox.id, parentId: parent.id, type: .task, title: "Final review", sortOrder: 2),
            MemoItem(listId: inbox.id, type: .note, title: "Welcome to PeekMemo", sortOrder: 1),
        ]
    }

    func children(of item: MemoItem) -> [MemoItem] {
        TaskHierarchy.children(of: item.id, in: items)
    }

    func progress(of item: MemoItem) -> (done: Int, total: Int) {
        TaskHierarchy.progress(of: item, in: items)
    }

    func beginComposing(parent: MemoItem? = nil) {
        editingItemID = nil
        isComposing = true
        composingParentID = parent?.id
        draftText = ""
    }

    func beginEditing(_ item: MemoItem) {
        isComposing = false
        composingParentID = nil
        editingItemID = item.id
        draftText = item.title
    }

    func saveDraft() {
        let text = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        let parent = composingParentID
        defer { cancelEdit() }
        guard !text.isEmpty else { return }
        let now = Date()
        if let id = editingItemID, let index = items.firstIndex(where: { $0.id == id }) {
            items[index].title = text
            items[index].updatedAt = now
            return
        }
        if isComposing {
            let siblings = parent == nil
                ? TaskHierarchy.roots(in: items, listId: selectedListID)
                : TaskHierarchy.children(of: parent!, in: items)
            let order = (siblings.last?.sortOrder ?? -1) + 1
            items.append(
                MemoItem(
                    listId: selectedListID,
                    parentId: parent,
                    type: .task,
                    title: text,
                    sortOrder: order,
                    createdAt: now,
                    updatedAt: now
                )
            )
        }
    }

    func cancelEdit() {
        isComposing = false
        composingParentID = nil
        editingItemID = nil
        draftText = ""
    }

    func toggleCompleted(_ item: MemoItem) {
        let completing = !item.isCompleted
        TaskHierarchy.setCompleted(item.id, to: completing, items: &items)
        if completing, item.parentId == nil {
            pendingHideIDs.insert(item.id)
        }
    }

    func finishHideAnimation(for id: UUID) {
        pendingHideIDs.remove(id)
    }

    func delete(_ item: MemoItem) {
        items.removeAll { $0.id == item.id || $0.parentId == item.id }
        if editingItemID == item.id {
            cancelEdit()
        }
    }
}
