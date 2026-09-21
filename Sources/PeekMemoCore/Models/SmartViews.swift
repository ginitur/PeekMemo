import Foundation

public enum SmartViewKind: String, Codable, Sendable, CaseIterable, Equatable {
    case today
    case inbox
    case completed
}

public enum NavigationID: Equatable, Hashable, Sendable, Codable {
    case smart(SmartViewKind)
    case list(UUID)
}

public enum SmartViews: Sendable {
    public static func isDueToday(_ item: MemoItem, calendar: Calendar = .current, now: Date = Date()) -> Bool {
        if item.forToday { return true }
        guard let due = item.dueDate else { return false }
        return calendar.isDate(due, inSameDayAs: now)
    }

    public static func todayRoots(in items: [MemoItem], calendar: Calendar = .current, now: Date = Date()) -> [MemoItem] {
        items.filter { item in
            item.parentId == nil
                && !item.isArchived
                && !item.isCompleted
                && isDueToday(item, calendar: calendar, now: now)
        }
        .sorted { $0.sortOrder < $1.sortOrder }
    }

    public static func inboxRoots(in items: [MemoItem], inboxID: UUID) -> [MemoItem] {
        TaskHierarchy.openRoots(in: items, listId: inboxID)
    }

    public static func completedAcrossLists(in items: [MemoItem]) -> [MemoItem] {
        items.filter { $0.parentId == nil && $0.isCompleted && !$0.isArchived }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }
}
