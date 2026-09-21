import Foundation
import PeekMemoCore

enum ScheduledDateTests {
    static func run() throws {
        try scheduledDateIsNotDueDate()
        try missingScheduleUsesLegacyFlagOnlyForToday()
    }

    static func scheduledDateIsNotDueDate() throws {
        let calendar = Calendar(identifier: .gregorian)
        let scheduled = Date(timeIntervalSince1970: 1_700_000_000)
        let due = DailyView.shiftDay(scheduled, by: 2, calendar: calendar)
        let item = MemoItem(
            listId: UUID(),
            title: "Split",
            sortOrder: 0,
            dueDate: due,
            scheduledDate: scheduled
        )
        try expect(DailyView.isScheduled(item, on: scheduled, calendar: calendar, now: scheduled))
        try expect(!DailyView.isScheduled(item, on: due, calendar: calendar, now: scheduled))
        try expectEqual(DailyView.dueRoots(in: [item], on: due, calendar: calendar, now: scheduled).count, 1)
    }

    static func missingScheduleUsesLegacyFlagOnlyForToday() throws {
        let now = Date()
        let item = MemoItem(listId: UUID(), title: "Flag", sortOrder: 0, forToday: true)
        try expect(DailyView.isScheduled(item, on: now, now: now))
        try expect(!DailyView.isScheduled(item, on: DailyView.shiftDay(now, by: -1), now: now))
    }
}
