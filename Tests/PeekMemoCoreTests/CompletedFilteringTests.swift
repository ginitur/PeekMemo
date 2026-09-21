import Foundation
import PeekMemoCore

enum CompletedFilteringTests {
    static func run() throws {
        try completedIsNotArchived()
        try openListHidesCompletedRoots()
    }

    static func completedIsNotArchived() throws {
        let list = UUID()
        let item = MemoItem(listId: list, title: "Done", isCompleted: true, completedAt: Date(), sortOrder: 0)
        try expect(item.isCompleted)
        try expect(!item.isArchived)
        try expect(SmartViews.completedAcrossLists(in: [item]).count == 1)
    }

    static func openListHidesCompletedRoots() throws {
        let list = UUID()
        let items = [
            MemoItem(listId: list, title: "Open", sortOrder: 0),
            MemoItem(listId: list, title: "Done", isCompleted: true, completedAt: Date(), sortOrder: 1),
        ]
        try expectEqual(TaskHierarchy.openRoots(in: items, listId: list).map(\.title), ["Open"])
        try expectEqual(TaskHierarchy.completedRoots(in: items, listId: list).map(\.title), ["Done"])
    }
}
