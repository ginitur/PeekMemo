import CoreGraphics
import Foundation

public enum TaskHierarchy: Sendable {
    public static func children(of parentID: UUID, in items: [MemoItem]) -> [MemoItem] {
        items.filter { $0.parentId == parentID && !$0.isArchived }.sorted { $0.sortOrder < $1.sortOrder }
    }

    public static func roots(in items: [MemoItem], categoryId: UUID? = nil) -> [MemoItem] {
        items.filter { item in
            item.parentId == nil
                && !item.isArchived
                && (categoryId == nil || item.categoryId == categoryId)
        }
        .sorted { $0.sortOrder < $1.sortOrder }
    }

    public static func progress(of parent: MemoItem, in items: [MemoItem]) -> (done: Int, total: Int) {
        let kids = children(of: parent.id, in: items)
        return (kids.filter(\.isCompleted).count, kids.count)
    }

    public static func canAddSubtask(_ item: MemoItem) -> Bool {
        item.type == .task && item.parentId == nil
    }

    public static let subtaskIndent: CGFloat = 18

    /// Completing a parent completes unfinished children. Completing the last child completes the parent.
    public static func setCompleted(_ id: UUID, to completed: Bool, items: inout [MemoItem], at date: Date = Date()) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        applyCompleted(&items[index], completed, at: date)

        let item = items[index]
        if item.parentId == nil, item.type == .task, completed {
            for child in children(of: item.id, in: items) where !child.isCompleted {
                if let childIndex = items.firstIndex(where: { $0.id == child.id }) {
                    applyCompleted(&items[childIndex], true, at: date)
                }
            }
        }

        if let parentId = item.parentId, completed {
            let siblings = children(of: parentId, in: items)
            if !siblings.isEmpty, siblings.allSatisfy(\.isCompleted) {
                if let parentIndex = items.firstIndex(where: { $0.id == parentId }) {
                    applyCompleted(&items[parentIndex], true, at: date)
                }
            }
        }

        if let parentId = item.parentId, !completed {
            if let parentIndex = items.firstIndex(where: { $0.id == parentId }), items[parentIndex].isCompleted {
                applyCompleted(&items[parentIndex], false, at: date)
            }
        }
    }

    private static func applyCompleted(_ item: inout MemoItem, _ completed: Bool, at date: Date) {
        item.isCompleted = completed
        item.completedAt = completed ? date : nil
        item.updatedAt = date
    }
}
