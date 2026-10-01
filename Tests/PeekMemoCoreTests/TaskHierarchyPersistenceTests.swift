import Foundation
import PeekMemoCore

enum TaskHierarchyPersistenceTests {
    static func run() throws {
        try subtaskInheritsParentAndStaysOutOfTheRootQuery()
        try notesAndSubtasksCannotOwnSubtasks()
    }

    static func subtaskInheritsParentAndStaysOutOfTheRootQuery() throws {
        let scratch = try PersistenceTestSupport.makeScratch()
        defer { PersistenceTestSupport.remove(scratch) }
        let store = try PersistenceTestSupport.open(scratch)
        let today = PersistenceTestSupport.today()
        let work = try store.categories.fetchCategories().first { $0.name == "Work" }
        guard let work else { throw CheckError(message: "missing Work") }

        let parent = try store.memos.createTask(title: "Parent", scheduledDate: today, categoryId: work.id)
        let child = try store.memos.createSubtask(parentID: parent.id, title: "Child")
        try expectEqual(child.categoryId, Optional(work.id))
        try expectEqual(child.scheduledDate, parent.scheduledDate)
        try expectEqual(child.parentId, parent.id)
        try expectEqual(child.type, .task)

        let roots = try store.memos.fetchItems(for: today)
        try expectEqual(roots.map(\.id), [parent.id])
        try expectEqual(try store.memos.fetchChildren(parentId: parent.id).map(\.id), [child.id])
    }

    static func notesAndSubtasksCannotOwnSubtasks() throws {
        let scratch = try PersistenceTestSupport.makeScratch()
        defer { PersistenceTestSupport.remove(scratch) }
        let store = try PersistenceTestSupport.open(scratch)
        let today = PersistenceTestSupport.today()
        let note = try store.memos.createNote(title: "Note", scheduledDate: today, categoryId: nil)
        let parent = try store.memos.createTask(title: "Parent", scheduledDate: today, categoryId: nil)
        let child = try store.memos.createSubtask(parentID: parent.id, title: "Child")

        do {
            _ = try store.memos.createSubtask(parentID: note.id, title: "Nope")
            try expect(false, "a note cannot have a subtask")
        } catch let error as PersistenceError {
            try expectEqual(error, .noteCannotHaveSubtask)
        }

        do {
            _ = try store.memos.createSubtask(parentID: child.id, title: "Nested")
            try expect(false, "a subtask cannot be nested")
        } catch let error as PersistenceError {
            try expectEqual(error, .cannotNestSubtask)
        }

        var nestedNote = note
        nestedNote.parentId = parent.id
        do {
            try store.memos.updateItem(nestedNote)
            try expect(false, "a note cannot be stored under a parent")
        } catch let error as PersistenceError {
            try expectEqual(error, .noteCannotHaveSubtask)
        }
    }
}
