import Foundation
import PeekMemoCore

enum PastUnfinishedPersistenceTests {
    static func run() throws {
        try unfinishedRootsFromEarlierDaysStayDated()
        try completedNotesAndSubtasksAreExcluded()
    }

    static func unfinishedRootsFromEarlierDaysStayDated() throws {
        let scratch = try PersistenceTestSupport.makeScratch()
        defer { PersistenceTestSupport.remove(scratch) }
        let store = try PersistenceTestSupport.open(scratch)
        let today = PersistenceTestSupport.today()
        let recent = PersistenceTestSupport.day(-1, from: today)
        let older = PersistenceTestSupport.day(-2, from: today)

        let olderTask = try store.memos.createTask(title: "Older", scheduledDate: older, categoryId: nil)
        let recentFirst = try store.memos.createTask(title: "Recent A", scheduledDate: recent, categoryId: nil)
        let recentSecond = try store.memos.createTask(title: "Recent B", scheduledDate: recent, categoryId: nil)
        _ = try store.memos.createTask(title: "Today", scheduledDate: today, categoryId: nil)

        let past = try store.memos.fetchPastUnfinished(before: today)
        try expectEqual(past.map(\.title), ["Recent A", "Recent B", "Older"])
        try expectEqual(past.map(\.id), [recentFirst.id, recentSecond.id, olderTask.id])
        try expectEqual(past[0].scheduledDate, Optional(recent))
        try expectEqual(past[2].scheduledDate, Optional(older))

        let again = try store.memos.fetchPastUnfinished(before: today)
        try expectEqual(again.map(\.scheduledDate), past.map(\.scheduledDate))
    }

    static func completedNotesAndSubtasksAreExcluded() throws {
        let scratch = try PersistenceTestSupport.makeScratch()
        defer { PersistenceTestSupport.remove(scratch) }
        let store = try PersistenceTestSupport.open(scratch)
        let today = PersistenceTestSupport.today()
        let yesterday = PersistenceTestSupport.day(-1, from: today)

        let done = try store.memos.createTask(title: "Done yesterday", scheduledDate: yesterday, categoryId: nil)
        try store.memos.toggleCompleted(id: done.id, at: yesterday.addingTimeInterval(3600))
        _ = try store.memos.createNote(title: "Yesterday note", scheduledDate: yesterday, categoryId: nil)
        let parent = try store.memos.createTask(title: "Yesterday parent", scheduledDate: yesterday, categoryId: nil)
        _ = try store.memos.createSubtask(parentID: parent.id, title: "Yesterday child")

        let past = try store.memos.fetchPastUnfinished(before: today)
        try expectEqual(past.map(\.title), ["Yesterday parent"])
        let yesterdayList = try store.memos.fetchItems(for: yesterday)
        try expectEqual(yesterdayList.map(\.title), ["Done yesterday", "Yesterday note", "Yesterday parent"])
        try expect(yesterdayList.contains(where: { $0.id == done.id && $0.isCompleted }))
    }
}
