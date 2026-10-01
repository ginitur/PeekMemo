import Foundation
import PeekMeowCore

enum MemoRepositoryTests {
    static func run() throws {
        try createUpdateDeleteAndReorder()
        try deletingParentDeletesChildren()
        try deletingChildKeepsParent()
        try missingItemThrows()
    }

    static func createUpdateDeleteAndReorder() throws {
        let scratch = try PersistenceTestSupport.makeScratch()
        defer { PersistenceTestSupport.remove(scratch) }
        let store = try PersistenceTestSupport.open(scratch)
        let today = PersistenceTestSupport.today()
        let first = try store.memos.createTask(title: "First", scheduledDate: today, categoryId: nil)
        let second = try store.memos.createTask(title: "Second", scheduledDate: today, categoryId: nil)
        try expectEqual(first.sortOrder, 0)
        try expectEqual(second.sortOrder, 1)

        var edited = second
        edited.title = "Second edited"
        try store.memos.updateItem(edited)
        try store.memos.reorderItems([second.id, first.id])

        let items = try store.memos.fetchItems(for: today)
        try expectEqual(items.map(\.title), ["Second edited", "First"])
        try expectEqual(items.map(\.sortOrder), [0, 1])

        try store.memos.deleteItem(id: second.id)
        try expectEqual(try store.memos.fetchItems(for: today).map(\.title), ["First"])
    }

    static func deletingParentDeletesChildren() throws {
        let scratch = try PersistenceTestSupport.makeScratch()
        defer { PersistenceTestSupport.remove(scratch) }
        let store = try PersistenceTestSupport.open(scratch)
        let today = PersistenceTestSupport.today()
        let parent = try store.memos.createTask(title: "Parent", scheduledDate: today, categoryId: nil)
        _ = try store.memos.createSubtask(parentID: parent.id, title: "Child")
        try store.memos.deleteItem(id: parent.id)
        let children = try store.memos.fetchChildren(parentId: parent.id)
        try expect(children.isEmpty)
        try expectEqual(try store.database.rowCount(in: "memo_items"), 0)
    }

    static func deletingChildKeepsParent() throws {
        let scratch = try PersistenceTestSupport.makeScratch()
        defer { PersistenceTestSupport.remove(scratch) }
        let store = try PersistenceTestSupport.open(scratch)
        let today = PersistenceTestSupport.today()
        let parent = try store.memos.createTask(title: "Parent", scheduledDate: today, categoryId: nil)
        let child = try store.memos.createSubtask(parentID: parent.id, title: "Child")
        let sibling = try store.memos.createSubtask(parentID: parent.id, title: "Sibling")
        try store.memos.deleteItem(id: child.id)
        try expectEqual(try store.memos.fetchItems(for: today).map(\.id), [parent.id])
        try expectEqual(try store.memos.fetchChildren(parentId: parent.id).map(\.id), [sibling.id])
    }

    static func missingItemThrows() throws {
        let scratch = try PersistenceTestSupport.makeScratch()
        defer { PersistenceTestSupport.remove(scratch) }
        let store = try PersistenceTestSupport.open(scratch)
        let missing = UUID()
        do {
            try store.memos.deleteItem(id: missing)
            try expect(false, "delete of a missing item should throw")
        } catch let error as PersistenceError {
            try expectEqual(error, .notFound(missing))
        }
    }
}
