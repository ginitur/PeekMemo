import Foundation
import Observation
import PeekMemoCore

/// In-memory prototype store. Lost on quit. Persistence is Phase 6.
@Observable
@MainActor
final class AppState {
    var lists: [UserList]
    var items: [MemoItem]
    var inboxID: UUID
    var navigation: NavigationID = .smart(.today)
    var editingItemID: UUID?
    var composingParentID: UUID?
    var draftText: String = ""
    var isComposing: Bool = false
    var completedExpanded = false
    var pendingHideIDs: Set<UUID> = []
    var expandedTaskIDs: Set<UUID> = []
    var selectedDate: Date = Calendar.current.startOfDay(for: Date())

    var selectedList: UserList? {
        switch navigation {
        case .list(let id):
            return lists.first(where: { $0.id == id })
        case .smart(.inbox):
            return lists.first(where: { $0.id == inboxID })
        case .smart:
            return nil
        }
    }

    var viewTitle: String {
        switch navigation {
        case .smart(.today): dailyTitle
        case .smart(.inbox): "Inbox"
        case .smart(.completed): "Completed"
        case .list(let id): lists.first(where: { $0.id == id })?.name ?? "List"
        }
    }

    var isDailyView: Bool { navigation == .smart(.today) }

    var dailyTitle: String {
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
        DailyView.rootTaskStats(in: items, on: selectedDate)
    }

    var customLists: [UserList] {
        lists.filter { $0.id != inboxID && !$0.isArchived }.sorted { $0.sortOrder < $1.sortOrder }
    }

    var openItems: [MemoItem] {
        switch navigation {
        case .smart(.today):
            DailyView.openScheduledRoots(in: items, on: selectedDate)
        case .smart(.inbox):
            SmartViews.inboxRoots(in: items, inboxID: inboxID)
        case .smart(.completed):
            []
        case .list(let id):
            TaskHierarchy.openRoots(in: items, listId: id)
        }
    }

    var completedItems: [MemoItem] {
        switch navigation {
        case .smart(.completed):
            SmartViews.completedAcrossLists(in: items)
        case .smart(.inbox):
            TaskHierarchy.completedRoots(in: items, listId: inboxID)
        case .smart(.today):
            DailyView.completedRoots(in: items, on: selectedDate)
        case .list(let id):
            TaskHierarchy.completedRoots(in: items, listId: id)
        }
    }

    var isEditing: Bool {
        isComposing || editingItemID != nil
    }

    init() {
        let calendar = Calendar.current
        let now = Date()
        let today = DailyView.startOfDay(now, calendar: calendar)
        let yesterday = DailyView.shiftDay(today, by: -1, calendar: calendar)
        let tomorrow = DailyView.shiftDay(today, by: 1, calendar: calendar)
        selectedDate = today
        let inbox = UserList(name: "Inbox", icon: "tray", color: .inbox, sortOrder: 0, createdAt: now, updatedAt: now)
        let work = UserList(name: "Work", icon: "briefcase", color: .today, sortOrder: 1, createdAt: now, updatedAt: now)
        let personal = UserList(name: "Personal", icon: "house", color: RGBAColor(red: 0.2, green: 0.7, blue: 0.45), sortOrder: 2, createdAt: now, updatedAt: now)
        let ideas = UserList(name: "Ideas", icon: "lightbulb", color: .ideas, sortOrder: 3, createdAt: now, updatedAt: now)
        lists = [inbox, work, personal, ideas]
        inboxID = inbox.id
        navigation = .smart(.today)
        let parent = MemoItem(
            listId: inbox.id,
            type: .task,
            title: "Prepare report",
            sortOrder: 0,
            scheduledDate: today,
            forToday: true,
            createdAt: now,
            updatedAt: now
        )
        let yesterdayDone = MemoItem(
            listId: work.id,
            type: .task,
            title: "Ship yesterday's notes",
            isCompleted: true,
            completedAt: yesterday.addingTimeInterval(15 * 3600),
            sortOrder: 0,
            scheduledDate: yesterday
        )
        let yesterdayLate = MemoItem(
            listId: work.id,
            type: .task,
            title: "Finish slides (done next day)",
            isCompleted: true,
            completedAt: today.addingTimeInterval(10 * 3600),
            sortOrder: 1,
            scheduledDate: yesterday
        )
        items = [
            parent,
            MemoItem(listId: inbox.id, parentId: parent.id, type: .task, title: "Collect data", isCompleted: true, completedAt: now, sortOrder: 0),
            MemoItem(listId: inbox.id, parentId: parent.id, type: .task, title: "Update charts", sortOrder: 1),
            MemoItem(listId: inbox.id, parentId: parent.id, type: .task, title: "Final review", sortOrder: 2),
            MemoItem(listId: work.id, type: .task, title: "Review pull request", sortOrder: 0, scheduledDate: today, forToday: true),
            MemoItem(listId: ideas.id, type: .note, title: "Welcome to PeekMemo", sortOrder: 0, scheduledDate: today),
            yesterdayDone,
            yesterdayLate,
            MemoItem(listId: personal.id, type: .task, title: "Call the accountant", sortOrder: 0, scheduledDate: tomorrow),
        ]
        expandedTaskIDs = [parent.id]
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

    /// Returns `true` when a subtask composer should stay open for the next item.
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
            let listID = targetListID(for: parent)
            let siblings = parent == nil
                ? TaskHierarchy.roots(in: items, listId: listID)
                : TaskHierarchy.children(of: parent!, in: items)
            let order = (siblings.last?.sortOrder ?? -1) + 1
            let schedule: Date? = isDailyView ? DailyView.startOfDay(selectedDate) : nil
            items.append(
                MemoItem(
                    listId: listID,
                    parentId: parent,
                    type: .task,
                    title: text,
                    sortOrder: order,
                    scheduledDate: schedule,
                    forToday: isDailyView && DailyView.isSameDay(selectedDate, Date()),
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

    func goToPreviousDay() {
        selectedDate = DailyView.shiftDay(selectedDate, by: -1)
        navigation = .smart(.today)
    }

    func goToNextDay() {
        selectedDate = DailyView.shiftDay(selectedDate, by: 1)
        navigation = .smart(.today)
    }

    func goToToday() {
        selectedDate = DailyView.startOfDay(Date())
        navigation = .smart(.today)
    }

    func cancelEdit() {
        isComposing = false
        composingParentID = nil
        editingItemID = nil
        draftText = ""
    }

    func toggleCompleted(_ item: MemoItem) {
        let completing = !item.isCompleted
        TaskHierarchy.setCompleted(item.id, to: completing, items: &items)
        if completing, item.parentId == nil {
            pendingHideIDs.insert(item.id)
        }
    }

    func finishHideAnimation(for id: UUID) {
        pendingHideIDs.remove(id)
    }

    func select(_ target: NavigationID) {
        navigation = target
        if target == .smart(.today) {
            selectedDate = DailyView.startOfDay(Date())
        }
        completedExpanded = (target == .smart(.completed))
        cancelEdit()
    }

    func addList(name: String = "New List") {
        let order = (customLists.last?.sortOrder ?? 0) + 1
        let list = UserList(name: name, icon: "folder", color: .accent, sortOrder: order)
        lists.append(list)
        navigation = .list(list.id)
    }

    func renameList(_ id: UUID, to name: String) {
        guard let index = lists.firstIndex(where: { $0.id == id }), id != inboxID else { return }
        lists[index].name = name
        lists[index].updatedAt = Date()
    }

    func archiveList(_ id: UUID) {
        guard id != inboxID, let index = lists.firstIndex(where: { $0.id == id }) else { return }
        lists[index].isArchived = true
        lists[index].updatedAt = Date()
        if navigation == .list(id) {
            navigation = .smart(.today)
        }
    }

    func moveList(_ id: UUID, by delta: Int) {
        var customs = customLists
        guard let index = customs.firstIndex(where: { $0.id == id }) else { return }
        let next = index + delta
        guard customs.indices.contains(next) else { return }
        customs.swapAt(index, next)
        for (order, list) in customs.enumerated() {
            if let i = lists.firstIndex(where: { $0.id == list.id }) {
                lists[i].sortOrder = order + 1
            }
        }
    }

    private func targetListID(for parent: UUID?) -> UUID {
        if let parent, let item = items.first(where: { $0.id == parent }) {
            return item.listId
        }
        switch navigation {
        case .list(let id):
            return id
        case .smart:
            return inboxID
        }
    }

    func delete(_ item: MemoItem) {
        items.removeAll { $0.id == item.id || $0.parentId == item.id }
        if editingItemID == item.id {
            cancelEdit()
        }
    }
}
