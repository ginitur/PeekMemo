import Foundation
import PeekMemoCore

enum DailyViewQueryTests {
    static func run() throws {
        try scheduledItemsAppearOnTheirDay()
        try dueWithoutScheduleIsSeparate()
        try notesDoNotEnterPercentage()
        try forTodayLegacyOnlyOnToday()
    }

    static func scheduledItemsAppearOnTheirDay() throws {
        let calendar = Calendar(identifier: .gregorian)
        let day = Date(timeIntervalSince1970: 1_700_000_000)
        let list = UUID()
        let items = [
            MemoItem(listId: list, title: "That day", sortOrder: 0, scheduledDate: day),
            MemoItem(listId: list, title: "Other day", sortOrder: 1, scheduledDate: DailyView.shiftDay(day, by: 1, calendar: calendar)),
        ]
        let found = DailyView.scheduledRoots(in: items, on: day, calendar: calendar, now: day)
        try expectEqual(found.map(\.title), ["That day"])
    }

    static func dueWithoutScheduleIsSeparate() throws {
        let calendar = Calendar(identifier: .gregorian)
        let day = Date(timeIntervalSince1970: 1_700_000_000)
        let list = UUID()
        let items = [
            MemoItem(listId: list, title: "Due only", sortOrder: 0, dueDate: day),
            MemoItem(listId: list, title: "Scheduled", sortOrder: 1, dueDate: day, scheduledDate: day),
        ]
        let due = DailyView.dueRoots(in: items, on: day, calendar: calendar, now: day)
        try expectEqual(due.map(\.title), ["Due only"])
    }

    static func notesDoNotEnterPercentage() throws {
        let day = Date(timeIntervalSince1970: 1_700_000_000)
        let list = UUID()
        let items = [
            MemoItem(listId: list, type: .task, title: "Task", sortOrder: 0, scheduledDate: day),
            MemoItem(listId: list, type: .note, title: "Note", sortOrder: 1, scheduledDate: day),
        ]
        let stats = DailyView.rootTaskStats(in: items, on: day, now: day)
        try expectEqual(stats.total, 1)
        try expectEqual(stats.completed, 0)
    }

    static func forTodayLegacyOnlyOnToday() throws {
        let calendar = Calendar(identifier: .gregorian)
        let today = Date(timeIntervalSince1970: 1_700_000_000)
        let yesterday = DailyView.shiftDay(today, by: -1, calendar: calendar)
        let list = UUID()
        let items = [MemoItem(listId: list, title: "Legacy", sortOrder: 0, forToday: true)]
        try expectEqual(DailyView.scheduledRoots(in: items, on: today, calendar: calendar, now: today).count, 1)
        try expectEqual(DailyView.scheduledRoots(in: items, on: yesterday, calendar: calendar, now: today).count, 0)
    }
}
