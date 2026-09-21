import PeekMemoCore

enum SubtaskIndentModelTests {
    static func run() throws {
        try indentIsEighteenPoints()
        try onlyRootTasksCanHaveSubtasks()
    }

    static func indentIsEighteenPoints() throws {
        try expectEqual(LayoutMetrics.subtaskIndent, 18)
        try expectEqual(TaskHierarchy.subtaskIndent, 18)
    }

    static func onlyRootTasksCanHaveSubtasks() throws {
        let parent = MemoItem(type: .task, title: "Parent", sortOrder: 0)
        let child = MemoItem(parentId: parent.id, type: .task, title: "Child", sortOrder: 0)
        let note = MemoItem(type: .note, title: "Note", sortOrder: 1)
        try expect(TaskHierarchy.canAddSubtask(parent))
        try expect(!TaskHierarchy.canAddSubtask(child))
        try expect(!TaskHierarchy.canAddSubtask(note))
    }
}
