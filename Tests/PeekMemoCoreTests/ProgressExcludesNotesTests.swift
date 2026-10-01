import Foundation
import PeekMemoCore

enum ProgressExcludesNotesTests {
    static func run() throws {
        try notesDoNotChangeDenominator()
        try subtasksDoNotChangeDailyTotal()
    }

    static func notesDoNotChangeDenominator() throws {
        let day = Date()
        let items = [
            MemoItem(type: .task, title: "Ship", isCompleted: true, completedAt: day, sortOrder: 0, scheduledDate: day),
            MemoItem(type: .task, title: "Open", sortOrder: 1, scheduledDate: day),
            MemoItem(type: .note, title: "Ask John", sortOrder: 2, scheduledDate: day),
        ]
        let stats = DailyView.rootTaskStats(in: items, on: day, now: day)
        try expectEqual(stats.completed, 1)
        try expectEqual(stats.total, 2)
    }

    static func subtasksDoNotChangeDailyTotal() throws {
        let day = Date()
        let parent = MemoItem(type: .task, title: "Parent", sortOrder: 0, scheduledDate: day)
        let child = MemoItem(parentId: parent.id, type: .task, title: "Child", sortOrder: 0, scheduledDate: day)
        let stats = DailyView.rootTaskStats(in: [parent, child], on: day, now: day)
        try expectEqual(stats.total, 1)
    }
}
