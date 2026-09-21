import Foundation
import Observation
import PeekMemoCore

/// In-memory prototype store. Lost on quit. Persistence is Phase 6.
@Observable
@MainActor
final class AppState {
    var groups: [MemoGroup]
    var memos: [Memo]
    var selectedGroupID: UUID
    var editingMemoID: UUID?
    var draftText: String = ""
    var isComposing: Bool = false

    var selectedGroup: MemoGroup? {
        groups.first(where: { $0.id == selectedGroupID })
    }

    var visibleMemos: [Memo] {
        memos
            .filter { $0.groupId == selectedGroupID && !$0.isArchived }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var isEditing: Bool {
        isComposing || editingMemoID != nil
    }

    init() {
        let now = Date()
        let today = MemoGroup(title: "Today", icon: "sun.max", color: .today, sortOrder: 0, createdAt: now, updatedAt: now)
        groups = [today]
        selectedGroupID = today.id
        memos = [
            Memo(groupId: today.id, text: "Example task", type: .checklist, sortOrder: 0, createdAt: now, updatedAt: now),
            Memo(groupId: today.id, text: "Another memo", type: .note, sortOrder: 1, createdAt: now, updatedAt: now),
        ]
    }

    func beginComposing() {
        editingMemoID = nil
        isComposing = true
        draftText = ""
    }

    func beginEditing(_ memo: Memo) {
        isComposing = false
        editingMemoID = memo.id
        draftText = memo.text
    }

    func saveDraft() {
        let text = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        defer { cancelEdit() }
        guard !text.isEmpty else { return }
        let now = Date()
        if let id = editingMemoID, let index = memos.firstIndex(where: { $0.id == id }) {
            memos[index].text = text
            memos[index].updatedAt = now
            return
        }
        if isComposing {
            let order = (visibleMemos.last?.sortOrder ?? -1) + 1
            memos.append(
                Memo(
                    groupId: selectedGroupID,
                    text: text,
                    type: .note,
                    sortOrder: order,
                    createdAt: now,
                    updatedAt: now
                )
            )
        }
    }

    func cancelEdit() {
        isComposing = false
        editingMemoID = nil
        draftText = ""
    }

    func toggleCompleted(_ memo: Memo) {
        guard let index = memos.firstIndex(where: { $0.id == memo.id }) else { return }
        memos[index].isCompleted.toggle()
        memos[index].updatedAt = Date()
        if memos[index].type == .note {
            memos[index].type = .checklist
        }
    }

    func delete(_ memo: Memo) {
        memos.removeAll { $0.id == memo.id }
        if editingMemoID == memo.id {
            cancelEdit()
        }
    }
}
