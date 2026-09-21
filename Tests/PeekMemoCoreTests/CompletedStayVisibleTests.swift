import Foundation
import PeekMemoCore

enum CompletedStayVisibleTests {
    static func run() throws {
        try completedRootStaysInDayList()
        try completedSubtaskStaysUnderParent()
    }

    static func completedRootStaysInDayList() throws {
        let day = Date()
        let work = UUID()
        var items = [
            MemoItem(categoryId: work, type: .task, title: "Ship", sortOrder: 0, scheduledDate: day),
        ]
        TaskHierarchy.setCompleted(items[0].id, to: true, items: &items)
        let visible = DailyView.scheduledRoots(in: items, on: day, now: day)
        try expectEqual(visible.count, 1)
        try expect(visible[0].isCompleted)
        try expectEqual(visible[0].title, "Ship")
    }

    static func completedSubtaskStaysUnderParent() throws {
        let parent = MemoItem(categoryId: UUID(), type: .task, title: "Parent", sortOrder: 0)
        var items = [
            parent,
            MemoItem(categoryId: parent.categoryId, parentId: parent.id, type: .task, title: "Child", sortOrder: 0),
        ]
        TaskHierarchy.setCompleted(items[1].id, to: true, items: &items)
        let kids = TaskHierarchy.children(of: parent.id, in: items)
        try expectEqual(kids.count, 1)
        try expect(kids[0].isCompleted)
    }
}
