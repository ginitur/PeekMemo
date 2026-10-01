import Foundation
import PeekMeowCore

enum DailyCategoryQueryTests {
    static func run() throws {
        try sameDayDifferentCategories()
    }

    static func sameDayDifferentCategories() throws {
        let day = Date()
        let work = UUID()
        let personal = UUID()
        let items = [
            MemoItem(categoryId: work, title: "Report", sortOrder: 0, scheduledDate: day),
            MemoItem(categoryId: personal, title: "Ink", sortOrder: 1, scheduledDate: day),
        ]
        try expectEqual(DailyView.scheduledRoots(in: items, on: day, categoryId: nil, now: day).count, 2)
        try expectEqual(DailyView.scheduledRoots(in: items, on: day, categoryId: work, now: day).map(\.title), ["Report"])
        try expectEqual(DailyView.scheduledRoots(in: items, on: day, categoryId: personal, now: day).map(\.title), ["Ink"])
    }
}
