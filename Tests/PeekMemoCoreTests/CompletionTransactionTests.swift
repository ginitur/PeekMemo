import Foundation
import PeekMemoCore

enum CompletionTransactionTests {
    static func run() throws {
        try parentAndChildCompletionRules()
    }

    static func parentAndChildCompletionRules() throws {
        let scratch = try PersistenceTestSupport.makeScratch()
        defer { PersistenceTestSupport.remove(scratch) }
        let store = try PersistenceTestSupport.open(scratch)
        let today = PersistenceTestSupport.today()
        let parent = try store.memos.createTask(title: "Parent", scheduledDate: today, categoryId: nil)
        let first = try store.memos.createSubtask(parentID: parent.id, title: "First")
        let second = try store.memos.createSubtask(parentID: parent.id, title: "Second")
        let morning = today.addingTimeInterval(3_600)
        let noon = today.addingTimeInterval(12 * 3_600)

        try store.memos.toggleCompleted(id: first.id, at: morning)
        var snapshot = try loadSnapshot(of: parent.id, store: store)
        try expectEqual(snapshot.parent.isCompleted, false)
        try expectEqual(snapshot.children[0].isCompleted, true)
        try expectEqual(snapshot.children[0].completedAt, Optional(morning))
        try expectEqual(snapshot.children[1].isCompleted, false)

        try store.memos.toggleCompleted(id: second.id, at: noon)
        snapshot = try loadSnapshot(of: parent.id, store: store)
        try expect(snapshot.parent.isCompleted)
        try expectEqual(snapshot.parent.completedAt, Optional(noon))
        try expect(snapshot.children.allSatisfy(\.isCompleted))

        try store.memos.toggleCompleted(id: first.id, at: noon.addingTimeInterval(60))
        snapshot = try loadSnapshot(of: parent.id, store: store)
        try expectEqual(snapshot.parent.isCompleted, false)
        try expectEqual(snapshot.parent.completedAt, nil)
        try expectEqual(snapshot.children[0].isCompleted, false)
        try expect(snapshot.children[1].isCompleted)
        try expectEqual(snapshot.children[1].completedAt, Optional(noon))

        try store.memos.toggleCompleted(id: parent.id, at: noon.addingTimeInterval(120))
        snapshot = try loadSnapshot(of: parent.id, store: store)
        try expect(snapshot.parent.isCompleted)
        try expect(snapshot.children.allSatisfy(\.isCompleted))
        try expectEqual(snapshot.children[0].completedAt, Optional(noon.addingTimeInterval(120)))
        try expectEqual(snapshot.children[1].completedAt, Optional(noon))

        let childStamp = snapshot.children[0].completedAt
        try store.memos.toggleCompleted(id: parent.id, at: noon.addingTimeInterval(180))
        snapshot = try loadSnapshot(of: parent.id, store: store)
        try expectEqual(snapshot.parent.isCompleted, false)
        try expectEqual(snapshot.parent.completedAt, nil)
        try expect(snapshot.children.allSatisfy(\.isCompleted))
        try expectEqual(snapshot.children[0].completedAt, childStamp)
    }

    private static func loadSnapshot(of parentID: UUID, store: MemoStore) throws -> (parent: MemoItem, children: [MemoItem]) {
        let today = PersistenceTestSupport.today()
        let roots = try store.memos.fetchItems(for: today)
        guard let parent = roots.first(where: { $0.id == parentID }) else {
            throw CheckError(message: "missing parent")
        }
        let children = try store.memos.fetchChildren(parentId: parentID)
        return (parent, children)
    }
}
