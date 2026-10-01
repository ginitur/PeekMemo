import Foundation
import PeekMemoCore

enum NotePersistenceTests {
    static func run() throws {
        try noteRoundTripsWithoutCompletionOrSubtasks()
    }

    static func noteRoundTripsWithoutCompletionOrSubtasks() throws {
        let scratch = try PersistenceTestSupport.makeScratch()
        defer { PersistenceTestSupport.remove(scratch) }
        let today = PersistenceTestSupport.today()
        let personalID: UUID
        let noteID: UUID
        do {
            let store = try PersistenceTestSupport.open(scratch)
            let personal = try store.categories.fetchCategories().first { $0.name == "Personal" }
            guard let personal else { throw CheckError(message: "missing Personal") }
            personalID = personal.id
            let note = try store.memos.createNote(
                title: "Remember to ask John about API",
                scheduledDate: today,
                categoryId: personal.id,
                body: "API"
            )
            noteID = note.id
            _ = try store.memos.createTask(title: "One task", scheduledDate: today, categoryId: nil)
        }

        let store = try PersistenceTestSupport.open(scratch)
        let day = try store.memos.fetchItems(for: today)
        guard let note = day.first(where: { $0.id == noteID }) else {
            throw CheckError(message: "note was not persisted")
        }
        try expectEqual(note.type, .note)
        try expectEqual(note.title, "Remember to ask John about API")
        try expectEqual(note.body, "API")
        try expectEqual(note.categoryId, Optional(personalID))
        try expectEqual(note.scheduledDate, Optional(today))
        try expectEqual(note.isCompleted, false)
        try expectEqual(note.completedAt, nil)
        try expectEqual(note.parentId, nil)

        let stats = DailyView.rootTaskStats(in: day, on: today)
        try expectEqual(stats.completed, 0)
        try expectEqual(stats.total, 1)

        do {
            try store.memos.toggleCompleted(id: note.id)
            try expect(false, "a note cannot be completed")
        } catch let error as PersistenceError {
            try expectEqual(error, .notesAreNotCompletable)
        }
        do {
            _ = try store.memos.createSubtask(parentID: note.id, title: "Nope")
            try expect(false, "a note cannot have a subtask")
        } catch let error as PersistenceError {
            try expectEqual(error, .noteCannotHaveSubtask)
        }
    }
}
