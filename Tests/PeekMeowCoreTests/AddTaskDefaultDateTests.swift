import Foundation
import PeekMeowCore

enum AddTaskDefaultDateTests {
    static func run() throws {
        try newTaskUsesSelectedDateAndCategory()
        try allFilterLeavesCategoryNil()
    }

    static func newTaskUsesSelectedDateAndCategory() throws {
        let day = DailyView.startOfDay(Date())
        let work = UUID()
        let item = MemoItem(
            categoryId: work,
            type: .task,
            title: "New",
            sortOrder: 0,
            scheduledDate: day
        )
        try expect(DailyView.isScheduled(item, on: day, now: day))
        try expectEqual(item.categoryId, work)
    }

    static func allFilterLeavesCategoryNil() throws {
        let day = DailyView.startOfDay(Date())
        let item = MemoItem(
            categoryId: nil,
            type: .task,
            title: "Loose",
            sortOrder: 0,
            scheduledDate: day
        )
        try expect(item.categoryId == nil)
        try expect(DailyView.matches(item, filter: nil))
        try expect(!DailyView.matches(item, filter: UUID()))
    }
}
