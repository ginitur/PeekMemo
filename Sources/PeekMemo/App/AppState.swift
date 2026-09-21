import Foundation
import Observation
import PeekMemoCore

/// In-memory prototype. Lost on quit. Persistence is Phase 6.
@Observable
@MainActor
final class AppState {
    var categories: [PeekMemoCore.Category]
    var items: [MemoItem]
    var selectedDate: Date = DailyView.startOfDay(Date())
    var categoryFilter: CategoryFilter = .all
    var showDatePicker = false
    var editingItemID: UUID?
    var composingParentID: UUID?
    var draftText: String = ""
    var isComposing: Bool = false
    var expandedTaskIDs: Set<UUID> = []

    var activeCategories: [PeekMemoCore.Category] {
        categories.filter { !$0.isArchived }.sorted { $0.sortOrder < $1.sortOrder }
    }

    var dateTitle: String {
        let calendar = Calendar.current
        let day = DailyView.startOfDay(selectedDate, calendar: calendar)
        let formatter = DateFormatter()
        formatter.locale = .current
        if DailyView.isSameDay(day, Date(), calendar: calendar) {
            formatter.dateFormat = "M月d日"
            return "\(formatter.string(from: day)) · 今天"
        }
        formatter.dateFormat = "M月d日 · EEE"
        return formatter.string(from: day)
    }

    var dailyStats: (completed: Int, total: Int) {
        DailyView.rootTaskStats(in: visibleDayItems, on: selectedDate)
    }

    var visibleDayItems: [MemoItem] {
        let categoryId: UUID? = {
            if case .category(let id) = categoryFilter { return id }
            return nil
        }()
        return DailyView.scheduledRoots(in: items, on: selectedDate, categoryId: categoryId)
    }

    var isEditing: Bool {
        isComposing || editingItemID != nil
    }

    var filterLabel: String {
        switch categoryFilter {
        case .all: "All"
        case .category(let id): categories.first(where: { $0.id == id })?.name ?? "All"
        }
    }

    init() {
        let calendar = Calendar.current
        let now = Date()
        let today = DailyView.startOfDay(now, calendar: calendar)
        let yesterday = DailyView.shiftDay(today, by: -1, calendar: calendar)
        let tomorrow = DailyView.shiftDay(today, by: 1, calendar: calendar)
        selectedDate = today
        let work = PeekMemoCore.Category(name: "Work", icon: "briefcase", color: .today, sortOrder: 0)
        let personal = PeekMemoCore.Category(name: "Personal", icon: "house", color: RGBAColor(red: 0.2, green: 0.7, blue: 0.45), sortOrder: 1)
        categories = [work, personal]
        let parent = MemoItem(
            categoryId: work.id,
            type: .task,
            title: "Prepare report",
            sortOrder: 0,
            scheduledDate: today
        )
        items = [
            parent,
            MemoItem(categoryId: work.id, parentId: parent.id, type: .task, title: "Collect data", isCompleted: true, completedAt: now, sortOrder: 0),
            MemoItem(categoryId: work.id, parentId: parent.id, type: .task, title: "Update charts", sortOrder: 1),
            MemoItem(categoryId: work.id, parentId: parent.id, type: .task, title: "Final review", sortOrder: 2),
            MemoItem(categoryId: work.id, type: .task, title: "Review pull request", sortOrder: 1, scheduledDate: today),
            MemoItem(categoryId: personal.id, type: .note, title: "Remember to ask John about API", sortOrder: 2, scheduledDate: today),
            MemoItem(
                categoryId: work.id,
                type: .task,
                title: "Ship yesterday's notes",
                isCompleted: true,
                completedAt: yesterday.addingTimeInterval(15 * 3600),
                sortOrder: 0,
                scheduledDate: yesterday
            ),
            MemoItem(categoryId: personal.id, type: .task, title: "Call the accountant", sortOrder: 0, scheduledDate: tomorrow),
        ]
        expandedTaskIDs = [parent.id]
    }

    func categoryForItem(_ item: MemoItem) -> PeekMemoCore.Category? {
        guard let id = item.categoryId else { return nil }
        return categories.first(where: { $0.id == id })
    }

    func children(of item: MemoItem) -> [MemoItem] {
        TaskHierarchy.children(of: item.id, in: items)
    }

    func progress(of item: MemoItem) -> (done: Int, total: Int) {
        TaskHierarchy.progress(of: item, in: items)
    }

    func beginComposing(parent: MemoItem? = nil) {
        editingItemID = nil
        isComposing = true
        composingParentID = parent?.id
        draftText = ""
        if let parent {
            expandedTaskIDs.insert(parent.id)
        }
    }

    func isTaskExpanded(_ id: UUID) -> Bool {
        expandedTaskIDs.contains(id)
    }

    func toggleTaskExpanded(_ id: UUID) {
        if expandedTaskIDs.contains(id) {
            expandedTaskIDs.remove(id)
        } else {
            expandedTaskIDs.insert(id)
        }
    }

    func beginEditing(_ item: MemoItem) {
        isComposing = false
        composingParentID = nil
        editingItemID = item.id
        draftText = item.title
    }

    @discardableResult
    func saveDraft(continueSubtask: Bool = false) -> Bool {
        let text = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        let parent = composingParentID
        if text.isEmpty {
            if continueSubtask, parent != nil { return true }
            cancelEdit()
            return false
        }
        let now = Date()
        if let id = editingItemID, let index = items.firstIndex(where: { $0.id == id }) {
            items[index].title = text
            items[index].updatedAt = now
            cancelEdit()
            return false
        }
        if isComposing {
            let categoryId = targetCategoryID(for: parent)
            let siblings = parent == nil
                ? visibleDayItems
                : TaskHierarchy.children(of: parent!, in: items)
            let order = (siblings.last?.sortOrder ?? -1) + 1
            items.append(
                MemoItem(
                    categoryId: categoryId,
                    parentId: parent,
                    type: .task,
                    title: text,
                    sortOrder: order,
                    scheduledDate: DailyView.startOfDay(selectedDate),
                    createdAt: now,
                    updatedAt: now
                )
            )
            if let parent {
                expandedTaskIDs.insert(parent)
            }
            if continueSubtask, parent != nil {
                draftText = ""
                isComposing = true
                composingParentID = parent
                editingItemID = nil
                return true
            }
        }
        cancelEdit()
        return false
    }

    func commitComposerIfNeeded() {
        let text = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            cancelEdit()
        } else {
            saveDraft(continueSubtask: false)
        }
    }

    func cancelEdit() {
        isComposing = false
        composingParentID = nil
        editingItemID = nil
        draftText = ""
    }

    func toggleCompleted(_ item: MemoItem) {
        TaskHierarchy.setCompleted(item.id, to: !item.isCompleted, items: &items)
    }

    func delete(_ item: MemoItem) {
        items.removeAll { $0.id == item.id || $0.parentId == item.id }
        if editingItemID == item.id {
            cancelEdit()
        }
    }

    func goToPreviousDay() {
        selectedDate = DailyView.shiftDay(selectedDate, by: -1)
    }

    func goToNextDay() {
        selectedDate = DailyView.shiftDay(selectedDate, by: 1)
    }

    func goToToday() {
        selectedDate = DailyView.startOfDay(Date())
    }

    func addCategory(name: String = "New Category") {
        let order = (activeCategories.last?.sortOrder ?? -1) + 1
        let category = PeekMemoCore.Category(name: name, icon: "folder", color: .accent, sortOrder: order)
        categories.append(category)
        categoryFilter = .category(category.id)
    }

    private func targetCategoryID(for parent: UUID?) -> UUID? {
        if let parent, let item = items.first(where: { $0.id == parent }) {
            return item.categoryId
        }
        if case .category(let id) = categoryFilter {
            return id
        }
        return nil
    }
}
