import Foundation
import PeekMemoCore

enum RestartPersistenceTests {
    static func run() throws {
        try quitAndRelaunchRestoresThenKeepsEdits()
    }

    static func quitAndRelaunchRestoresThenKeepsEdits() throws {
        let scratch = try PersistenceTestSupport.makeScratch()
        defer { PersistenceTestSupport.remove(scratch) }
        let today = PersistenceTestSupport.today()
        let yesterday = PersistenceTestSupport.day(-1, from: today)

        let workID: UUID
        let personalID: UUID
        let reportID: UUID
        let collectID: UUID
        let draftID: UUID
        let inkID: UUID
        let noteID: UUID
        let leftoverID: UUID

        do {
            let store = try PersistenceTestSupport.open(scratch)
            let categories = try store.categories.fetchCategories()
            guard let work = categories.first(where: { $0.name == "Work" }),
                  let personal = categories.first(where: { $0.name == "Personal" })
            else {
                throw CheckError(message: "missing default categories")
            }
            workID = work.id
            personalID = personal.id

            let report = try store.memos.createTask(title: "Prepare report", scheduledDate: today, categoryId: work.id)
            let collect = try store.memos.createSubtask(parentID: report.id, title: "Collect data")
            let draft = try store.memos.createSubtask(parentID: report.id, title: "Write draft")
            try store.memos.toggleCompleted(id: collect.id, at: today.addingTimeInterval(1_800))
            let ink = try store.memos.createTask(title: "Buy ink", scheduledDate: today, categoryId: personal.id)
            let note = try store.memos.createNote(title: "A plain note", scheduledDate: today, categoryId: nil)
            let leftover = try store.memos.createTask(
                title: "Finish the outline",
                scheduledDate: yesterday,
                categoryId: work.id
            )
            reportID = report.id
            collectID = collect.id
            draftID = draft.id
            inkID = ink.id
            noteID = note.id
            leftoverID = leftover.id
        }

        let followUpID: UUID
        do {
            let store = try PersistenceTestSupport.open(scratch)
            try assertFirstLaunch(
                store: store,
                today: today,
                yesterday: yesterday,
                workID: workID,
                personalID: personalID,
                reportID: reportID,
                collectID: collectID,
                draftID: draftID,
                inkID: inkID,
                noteID: noteID,
                leftoverID: leftoverID
            )

            try store.memos.toggleCompleted(id: draftID, at: today.addingTimeInterval(7_200))
            guard var ink = try store.memos.fetchItems(for: today).first(where: { $0.id == inkID }) else {
                throw CheckError(message: "Buy ink missing after restart")
            }
            ink.title = "Buy ink cartridges"
            try store.memos.updateItem(ink)
            let followUp = try store.memos.createTask(title: "Follow up", scheduledDate: today, categoryId: workID)
            followUpID = followUp.id
        }

        let store = try PersistenceTestSupport.open(scratch)
        let categories = try store.categories.fetchCategories()
        try expectEqual(categories.map(\.id), [workID, personalID])

        let day = try store.memos.fetchItems(for: today)
        try expectEqual(day.map(\.title), ["Prepare report", "Buy ink cartridges", "A plain note", "Follow up"])
        try expectEqual(day.map(\.id), [reportID, inkID, noteID, followUpID])
        guard let report = day.first(where: { $0.id == reportID }) else {
            throw CheckError(message: "report missing")
        }
        try expect(report.isCompleted)
        try expectEqual(report.categoryId, Optional(workID))
        let children = try store.memos.fetchChildren(parentId: reportID)
        try expectEqual(children.map(\.title), ["Collect data", "Write draft"])
        try expect(children.allSatisfy(\.isCompleted))

        guard let note = day.first(where: { $0.id == noteID }) else {
            throw CheckError(message: "note missing")
        }
        try expectEqual(note.type, .note)
        try expectEqual(note.categoryId, nil)

        let past = try store.memos.fetchPastUnfinished(before: today)
        try expectEqual(past.map(\.id), [leftoverID])
        guard let leftover = past.first else { throw CheckError(message: "missing leftover") }
        try expectEqual(leftover.scheduledDate, Optional(yesterday))
        try expectEqual(leftover.isCompleted, false)
        let yesterdayList = try store.memos.fetchItems(for: yesterday)
        try expectEqual(yesterdayList.map(\.id), [leftoverID])
        try expect(!yesterdayList.contains(where: { $0.id == reportID }))

        let stats = DailyView.rootTaskStats(in: day, on: today)
        try expectEqual(stats.total, 3)
        try expectEqual(stats.completed, 1)
    }

    private static func assertFirstLaunch(
        store: MemoStore,
        today: Date,
        yesterday: Date,
        workID: UUID,
        personalID: UUID,
        reportID: UUID,
        collectID: UUID,
        draftID: UUID,
        inkID: UUID,
        noteID: UUID,
        leftoverID: UUID
    ) throws {
        let categories = try store.categories.fetchCategories()
        try expectEqual(categories.map(\.id), [workID, personalID])
        try expectEqual(categories.map(\.name), ["Work", "Personal"])

        let day = try store.memos.fetchItems(for: today)
        try expectEqual(day.map(\.title), ["Prepare report", "Buy ink", "A plain note"])
        try expectEqual(day.map(\.sortOrder), [0, 1, 2])
        guard let report = day.first(where: { $0.id == reportID }),
              let ink = day.first(where: { $0.id == inkID }),
              let note = day.first(where: { $0.id == noteID })
        else {
            throw CheckError(message: "today's items did not survive restart")
        }
        try expectEqual(report.categoryId, Optional(workID))
        try expectEqual(report.isCompleted, false)
        try expectEqual(ink.categoryId, Optional(personalID))
        try expectEqual(note.type, .note)
        try expectEqual(note.categoryId, nil)
        try expectEqual(note.isCompleted, false)

        let children = try store.memos.fetchChildren(parentId: reportID)
        try expectEqual(children.map(\.id), [collectID, draftID])
        try expectEqual(children[0].isCompleted, true)
        try expectEqual(children[0].title, "Collect data")
        try expectEqual(children[1].isCompleted, false)
        try expectEqual(children[1].title, "Write draft")

        let past = try store.memos.fetchPastUnfinished(before: today)
        try expectEqual(past.map(\.id), [leftoverID])
        guard let leftover = past.first else { throw CheckError(message: "missing leftover") }
        try expectEqual(leftover.scheduledDate, Optional(yesterday))
        try expectEqual(leftover.categoryId, Optional(workID))
        let yesterdayList = try store.memos.fetchItems(for: yesterday)
        try expectEqual(yesterdayList.map(\.id), [leftoverID])
        try expectEqual(yesterdayList.first?.isCompleted, false)
    }
}
