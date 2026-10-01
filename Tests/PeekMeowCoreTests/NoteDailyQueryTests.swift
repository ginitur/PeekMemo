import Foundation
import PeekMeowCore

enum NoteDailyQueryTests {
    static func run() throws {
        try noteScheduledTodayAppears()
        try noteCannotHaveSubtask()
        try noteIsNotACompletionTask()
    }

    static func noteScheduledTodayAppears() throws {
        let day = Date()
        let items = [
            MemoItem(type: .note, title: "Remember to ask John about API", sortOrder: 0, scheduledDate: day),
        ]
        let roots = DailyView.scheduledRoots(in: items, on: day, now: day)
        try expectEqual(roots.map(\.title), ["Remember to ask John about API"])
        try expectEqual(roots[0].type, .note)
    }

    static func noteCannotHaveSubtask() throws {
        let note = MemoItem(type: .note, title: "Memo", sortOrder: 0)
        try expect(!TaskHierarchy.canAddSubtask(note))
    }

    static func noteIsNotACompletionTask() throws {
        let day = Date()
        let note = MemoItem(
            type: .note,
            title: "Memo",
            isCompleted: true,
            completedAt: day,
            sortOrder: 0,
            scheduledDate: day
        )
        try expect(!DailyView.isCompleted(note, asOf: day))
    }
}
