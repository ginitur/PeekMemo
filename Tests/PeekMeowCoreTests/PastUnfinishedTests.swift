import Foundation
import PeekMeowCore

enum PastUnfinishedTests {
    static func run() throws {
        try unfinishedYesterdayAppearsOnToday()
        try yesterdayViewShowsItInTheDayList()
        try completedYesterdayDoesNotAppearOnToday()
        try notesAreNotPastUnfinished()
    }

    static func unfinishedYesterdayAppearsOnToday() throws {
        let calendar = Calendar(identifier: .gregorian)
        let today = Date(timeIntervalSince1970: 1_700_000_000)
        let yesterday = DailyView.shiftDay(today, by: -1, calendar: calendar)
        let items = [
            MemoItem(type: .task, title: "Outline", sortOrder: 0, scheduledDate: yesterday),
            MemoItem(type: .task, title: "Today", sortOrder: 0, scheduledDate: today),
        ]
        let past = DailyView.pastUnfinishedRoots(in: items, before: today, calendar: calendar)
        try expectEqual(past.map(\.title), ["Outline"])
        try expectEqual(past[0].scheduledDate, yesterday)
        try expect(DailyView.isViewingToday(today, now: today, calendar: calendar))
        try expect(!DailyView.isViewingToday(yesterday, now: today, calendar: calendar))
    }

    static func yesterdayViewShowsItInTheDayList() throws {
        let calendar = Calendar(identifier: .gregorian)
        let today = Date(timeIntervalSince1970: 1_700_000_000)
        let yesterday = DailyView.shiftDay(today, by: -1, calendar: calendar)
        let items = [
            MemoItem(type: .task, title: "Outline", sortOrder: 0, scheduledDate: yesterday),
        ]
        let day = DailyView.scheduledRoots(in: items, on: yesterday, calendar: calendar, now: today)
        try expectEqual(day.map(\.title), ["Outline"])
        try expect(DailyView.pastUnfinishedRoots(in: items, before: yesterday, calendar: calendar).isEmpty)
    }

    static func completedYesterdayDoesNotAppearOnToday() throws {
        let calendar = Calendar(identifier: .gregorian)
        let today = Date(timeIntervalSince1970: 1_700_000_000)
        let yesterday = DailyView.shiftDay(today, by: -1, calendar: calendar)
        let items = [
            MemoItem(
                type: .task,
                title: "Done",
                isCompleted: true,
                completedAt: yesterday,
                sortOrder: 0,
                scheduledDate: yesterday
            ),
        ]
        try expect(DailyView.pastUnfinishedRoots(in: items, before: today, calendar: calendar).isEmpty)
    }

    static func notesAreNotPastUnfinished() throws {
        let calendar = Calendar(identifier: .gregorian)
        let today = Date(timeIntervalSince1970: 1_700_000_000)
        let yesterday = DailyView.shiftDay(today, by: -1, calendar: calendar)
        let items = [
            MemoItem(type: .note, title: "Old note", sortOrder: 0, scheduledDate: yesterday),
        ]
        try expect(DailyView.pastUnfinishedRoots(in: items, before: today, calendar: calendar).isEmpty)
    }
}
