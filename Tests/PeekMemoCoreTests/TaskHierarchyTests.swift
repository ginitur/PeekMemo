import Foundation
import PeekMemoCore

enum TaskHierarchyTests {
    static func run() throws {
        try completingParentCompletesChildren()
        try completingLastChildCompletesParent()
        try uncompletingParentLeavesChildren()
        try uncompletingChildReopensParent()
        try cannotNestThreeLevelsInUIRule()
        try progressCounts()
    }

    static func completingParentCompletesChildren() throws {
        var items = sample()
        TaskHierarchy.setCompleted(items[0].id, to: true, items: &items, at: Date(timeIntervalSince1970: 1000))
        try expect(items[0].isCompleted)
        try expect(items[1].isCompleted)
        try expect(items[2].isCompleted)
        try expect(items[1].completedAt != nil)
    }

    static func completingLastChildCompletesParent() throws {
        var items = sample()
        TaskHierarchy.setCompleted(items[1].id, to: true, items: &items)
        try expect(!items[0].isCompleted)
        TaskHierarchy.setCompleted(items[2].id, to: true, items: &items)
        try expect(items[0].isCompleted)
    }

    static func uncompletingParentLeavesChildren() throws {
        var items = sample()
        TaskHierarchy.setCompleted(items[0].id, to: true, items: &items)
        TaskHierarchy.setCompleted(items[0].id, to: false, items: &items)
        try expect(!items[0].isCompleted)
        try expect(items[0].completedAt == nil)
        try expect(items[1].isCompleted)
        try expect(items[2].isCompleted)
    }

    static func uncompletingChildReopensParent() throws {
        var items = sample()
        TaskHierarchy.setCompleted(items[0].id, to: true, items: &items)
        TaskHierarchy.setCompleted(items[1].id, to: false, items: &items)
        try expect(!items[0].isCompleted)
        try expect(!items[1].isCompleted)
        try expect(items[2].isCompleted)
    }

    static func cannotNestThreeLevelsInUIRule() throws {
        let parent = sample()[0]
        let child = sample()[1]
        try expect(TaskHierarchy.canAddSubtask(parent))
        try expect(!TaskHierarchy.canAddSubtask(child))
    }

    static func progressCounts() throws {
        let items = sample()
        let progress = TaskHierarchy.progress(of: items[0], in: items)
        try expectEqual(progress.done, 0)
        try expectEqual(progress.total, 2)
    }

    private static func sample() -> [MemoItem] {
        let list = UUID()
        let parent = MemoItem(categoryId: list, type: .task, title: "Prepare report", sortOrder: 0)
        let a = MemoItem(categoryId: list, parentId: parent.id, type: .task, title: "Collect data", sortOrder: 0)
        let b = MemoItem(categoryId: list, parentId: parent.id, type: .task, title: "Update charts", sortOrder: 1)
        return [parent, a, b]
    }
}
