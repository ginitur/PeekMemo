import Foundation
import PeekMemoCore

enum TaskCompletionTests {
    static func run() throws {
        try notesStayNotesWhenCompleted()
    }

    static func notesStayNotesWhenCompleted() throws {
        var items = [MemoItem(categoryId: UUID(), type: .note, title: "A note", sortOrder: 0)]
        TaskHierarchy.setCompleted(items[0].id, to: true, items: &items)
        try expect(items[0].isCompleted)
        try expectEqual(items[0].type, .note)
    }
}
