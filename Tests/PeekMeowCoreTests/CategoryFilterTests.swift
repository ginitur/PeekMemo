import Foundation
import PeekMeowCore

enum CategoryFilterTests {
    static func run() throws {
        try allShowsEveryCategory()
        try filterHidesOtherCategories()
        try uncategorizedOnlyInAll()
    }

    static func allShowsEveryCategory() throws {
        let day = Date()
        let work = UUID()
        let personal = UUID()
        let items = [
            MemoItem(categoryId: work, title: "Work task", sortOrder: 0, scheduledDate: day),
            MemoItem(categoryId: personal, title: "Personal task", sortOrder: 1, scheduledDate: day),
            MemoItem(categoryId: nil, title: "Loose", sortOrder: 2, scheduledDate: day),
        ]
        let all = DailyView.scheduledRoots(in: items, on: day, categoryId: nil, now: day)
        try expectEqual(all.count, 3)
    }

    static func filterHidesOtherCategories() throws {
        let day = Date()
        let work = UUID()
        let personal = UUID()
        let items = [
            MemoItem(categoryId: work, title: "Work task", sortOrder: 0, scheduledDate: day),
            MemoItem(categoryId: personal, title: "Personal task", sortOrder: 1, scheduledDate: day),
        ]
        let workOnly = DailyView.scheduledRoots(in: items, on: day, categoryId: work, now: day)
        try expectEqual(workOnly.map(\.title), ["Work task"])
    }

    static func uncategorizedOnlyInAll() throws {
        let day = Date()
        let work = UUID()
        let items = [
            MemoItem(categoryId: nil, title: "Loose", sortOrder: 0, scheduledDate: day),
            MemoItem(categoryId: work, title: "Work", sortOrder: 1, scheduledDate: day),
        ]
        let filtered = DailyView.scheduledRoots(in: items, on: day, categoryId: work, now: day)
        try expectEqual(filtered.map(\.title), ["Work"])
    }
}
