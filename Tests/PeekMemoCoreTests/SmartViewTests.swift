import Foundation
import PeekMemoCore

enum SmartViewTests {
    static func run() throws {
        try todayUsesDueDateAndFlag()
        try inboxIsTheDefaultList()
        try completedAggregatesAllLists()
    }

    static func todayUsesDueDateAndFlag() throws {
        let inbox = UUID()
        let work = UUID()
        let calendar = Calendar(identifier: .gregorian)
        let today = Date(timeIntervalSince1970: 1_700_000_000)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let items = [
            MemoItem(listId: inbox, title: "Flagged", sortOrder: 0, forToday: true),
            MemoItem(listId: work, title: "Due today", sortOrder: 1, dueDate: today),
            MemoItem(listId: work, title: "Due yesterday", sortOrder: 2, dueDate: yesterday),
            MemoItem(listId: inbox, title: "Plain inbox", sortOrder: 3),
        ]
        let todayItems = SmartViews.todayRoots(in: items, calendar: calendar, now: today)
        try expectEqual(Set(todayItems.map(\.title)), ["Flagged", "Due today"])
    }

    static func inboxIsTheDefaultList() throws {
        let inbox = UUID()
        let work = UUID()
        let items = [
            MemoItem(listId: inbox, title: "In inbox", sortOrder: 0),
            MemoItem(listId: work, title: "At work", sortOrder: 0),
        ]
        let inboxItems = SmartViews.inboxRoots(in: items, inboxID: inbox)
        try expectEqual(inboxItems.map(\.title), ["In inbox"])
    }

    static func completedAggregatesAllLists() throws {
        let a = UUID()
        let b = UUID()
        let t1 = Date(timeIntervalSince1970: 50)
        let t2 = Date(timeIntervalSince1970: 100)
        let items = [
            MemoItem(listId: a, title: "Old", isCompleted: true, completedAt: t1, sortOrder: 0),
            MemoItem(listId: b, title: "New", isCompleted: true, completedAt: t2, sortOrder: 0),
            MemoItem(listId: a, title: "Open", sortOrder: 1),
        ]
        let done = SmartViews.completedAcrossLists(in: items)
        try expectEqual(done.map(\.title), ["New", "Old"])
    }
}
