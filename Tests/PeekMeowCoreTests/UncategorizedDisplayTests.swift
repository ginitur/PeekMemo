import Foundation
import PeekMeowCore

enum UncategorizedDisplayTests {
    static func run() throws {
        try nilCategoryHasNoBadge()
        try namedCategoryHasBadge()
        try allStillIncludesUncategorized()
    }

    static func nilCategoryHasNoBadge() throws {
        let item = MemoItem(categoryId: nil, title: "Loose thought", sortOrder: 0)
        try expect(DailyView.categoryBadgeName(for: item, in: []) == nil)
    }

    static func namedCategoryHasBadge() throws {
        let work = Category(name: "Work", icon: "briefcase", color: .today, sortOrder: 0)
        let item = MemoItem(categoryId: work.id, title: "Report", sortOrder: 0)
        try expectEqual(DailyView.categoryBadgeName(for: item, in: [work]), "Work")
    }

    static func allStillIncludesUncategorized() throws {
        let day = Date()
        let items = [
            MemoItem(categoryId: nil, title: "Loose", sortOrder: 0, scheduledDate: day),
        ]
        try expectEqual(DailyView.scheduledRoots(in: items, on: day, categoryId: nil, now: day).count, 1)
        try expect(DailyView.scheduledRoots(in: items, on: day, categoryId: UUID(), now: day).isEmpty)
    }
}
