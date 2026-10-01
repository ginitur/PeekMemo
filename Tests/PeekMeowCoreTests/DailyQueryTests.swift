import Foundation
import PeekMeowCore

enum DailyQueryTests {
    static func run() throws {
        try dayBoundsIncludeCompletedAndExcludeSubtasks()
        try nilCategoryIsIncludedInAll()
    }

    static func dayBoundsIncludeCompletedAndExcludeSubtasks() throws {
        let scratch = try PersistenceTestSupport.makeScratch()
        defer { PersistenceTestSupport.remove(scratch) }
        let store = try PersistenceTestSupport.open(scratch)
        let today = PersistenceTestSupport.today()
        let tomorrow = PersistenceTestSupport.nextDay(today)

        let open = try store.memos.createTask(title: "Open", scheduledDate: today, categoryId: nil)
        let done = try store.memos.createTask(title: "Done", scheduledDate: today, categoryId: nil)
        try store.memos.toggleCompleted(id: done.id, at: today.addingTimeInterval(3600))
        let child = try store.memos.createSubtask(parentID: open.id, title: "Child")
        _ = try store.memos.createTask(title: "Tomorrow", scheduledDate: tomorrow, categoryId: nil)

        var late = try store.memos.createTask(title: "Late", scheduledDate: today, categoryId: nil)
        late.scheduledDate = tomorrow.addingTimeInterval(-1)
        try store.memos.updateItem(late)

        let day = try store.memos.fetchItems(for: today)
        try expectEqual(day.map(\.title), ["Open", "Done", "Late"])
        try expect(day.contains(where: { $0.id == done.id && $0.isCompleted }))
        try expect(!day.contains(where: { $0.id == child.id }))

        late.scheduledDate = tomorrow
        try store.memos.updateItem(late)
        let afterMidnight = try store.memos.fetchItems(for: today)
        try expect(!afterMidnight.contains(where: { $0.id == late.id }))
        let nextDay = try store.memos.fetchItems(for: tomorrow)
        try expect(nextDay.contains(where: { $0.id == late.id }))
    }

    static func nilCategoryIsIncludedInAll() throws {
        let scratch = try PersistenceTestSupport.makeScratch()
        defer { PersistenceTestSupport.remove(scratch) }
        let store = try PersistenceTestSupport.open(scratch)
        let today = PersistenceTestSupport.today()
        let note = try store.memos.createNote(title: "Loose note", scheduledDate: today, categoryId: nil)
        let all = try store.memos.fetchItems(for: today)
        try expectEqual(all.map(\.id), [note.id])
        try expectEqual(all.first?.categoryId, nil)
    }
}

extension PersistenceTestSupport {
    static func nextDay(_ day: Date) -> Date {
        DailyView.nextDayStart(day)
    }
}
