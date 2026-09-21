import Foundation
import PeekMemoCore

enum DailyCompletionAsOfTests {
    static func run() throws {
        try completedNextDayDoesNotRewriteYesterday()
        try completedSameDayCounts()
        try incompleteHasNoCompletedAt()
        try notesNeverCountAsCompletedTasks()
    }

    static func completedNextDayDoesNotRewriteYesterday() throws {
        let calendar = Calendar(identifier: .gregorian)
        let sep20 = Date(timeIntervalSince1970: 1_695_168_000)
        let sep21 = DailyView.shiftDay(sep20, by: 1, calendar: calendar)
        let list = UUID()
        let item = MemoItem(
            categoryId: list,
            type: .task,
            title: "Slides",
            isCompleted: true,
            completedAt: sep21.addingTimeInterval(10 * 3600),
            sortOrder: 0,
            scheduledDate: sep20
        )
        try expect(!DailyView.isCompleted(item, asOf: sep20, calendar: calendar))
        try expect(DailyView.isCompleted(item, asOf: sep21, calendar: calendar))
        let yesterdayStats = DailyView.rootTaskStats(in: [item], on: sep20, calendar: calendar, now: sep21)
        try expectEqual(yesterdayStats.completed, 0)
        try expectEqual(yesterdayStats.total, 1)
    }

    static func completedSameDayCounts() throws {
        let calendar = Calendar(identifier: .gregorian)
        let sep20 = Date(timeIntervalSince1970: 1_695_168_000)
        let list = UUID()
        let item = MemoItem(
            categoryId: list,
            type: .task,
            title: "Notes",
            isCompleted: true,
            completedAt: sep20.addingTimeInterval(15 * 3600),
            sortOrder: 0,
            scheduledDate: sep20
        )
        try expect(DailyView.isCompleted(item, asOf: sep20, calendar: calendar))
        let stats = DailyView.rootTaskStats(in: [item], on: sep20, calendar: calendar, now: sep20)
        try expectEqual(stats.completed, 1)
        try expectEqual(stats.total, 1)
    }

    static func incompleteHasNoCompletedAt() throws {
        let day = Date()
        let item = MemoItem(categoryId: UUID(), type: .task, title: "Open", sortOrder: 0, scheduledDate: day)
        try expect(!DailyView.isCompleted(item, asOf: day))
    }

    static func notesNeverCountAsCompletedTasks() throws {
        let day = Date()
        let item = MemoItem(
            categoryId: UUID(),
            type: .note,
            title: "Note",
            isCompleted: true,
            completedAt: day,
            sortOrder: 0,
            scheduledDate: day
        )
        try expect(!DailyView.isCompleted(item, asOf: day))
        let stats = DailyView.rootTaskStats(in: [item], on: day, now: day)
        try expectEqual(stats.total, 0)
    }
}
