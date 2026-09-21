import Foundation
import PeekMemoCore

enum TaskCompletionTests {
    static func run() throws {
        try completedItemsAreHiddenFromOpenRoots()
        try completedRootsStayInCompletedSection()
        try notesAreNotAutoPromotedWhenCompleting()
    }

    static func completedItemsAreHiddenFromOpenRoots() throws {
        let list = UUID()
        var items = [
            MemoItem(listId: list, type: .task, title: "Open", sortOrder: 0),
            MemoItem(listId: list, type: .task, title: "Done", isCompleted: true, completedAt: Date(), sortOrder: 1),
        ]
        try expectEqual(TaskHierarchy.openRoots(in: items, listId: list).count, 1)
        try expectEqual(TaskHierarchy.completedRoots(in: items, listId: list).count, 1)
        TaskHierarchy.setCompleted(items[0].id, to: true, items: &items)
        try expectEqual(TaskHierarchy.openRoots(in: items, listId: list).count, 0)
        try expectEqual(TaskHierarchy.completedRoots(in: items, listId: list).count, 2)
    }

    static func completedRootsStayInCompletedSection() throws {
        let list = UUID()
        let items = [
            MemoItem(listId: list, type: .task, title: "Done", isCompleted: true, completedAt: Date(), sortOrder: 0),
        ]
        try expectEqual(TaskHierarchy.completedRoots(in: items, listId: list).first?.title, "Done")
        try expect(items[0].isArchived == false)
    }

    static func notesAreNotAutoPromotedWhenCompleting() throws {
        let list = UUID()
        var items = [MemoItem(listId: list, type: .note, title: "A note", sortOrder: 0)]
        TaskHierarchy.setCompleted(items[0].id, to: true, items: &items)
        try expect(items[0].isCompleted)
        try expectEqual(items[0].type, .note)
    }
}
