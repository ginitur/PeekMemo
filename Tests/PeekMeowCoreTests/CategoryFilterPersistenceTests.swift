import Foundation
import PeekMeowCore

/// SQLite category filter. The in-memory Daily View suite keeps the name `CategoryFilterTests`.
enum CategoryFilterPersistenceTests {
    static func run() throws {
        try filterMatchesCategoryAndAllIncludesNil()
    }

    static func filterMatchesCategoryAndAllIncludesNil() throws {
        let scratch = try PersistenceTestSupport.makeScratch()
        defer { PersistenceTestSupport.remove(scratch) }
        let store = try PersistenceTestSupport.open(scratch)
        let today = PersistenceTestSupport.today()
        let categories = try store.categories.fetchCategories()
        guard let work = categories.first(where: { $0.name == "Work" }),
              let personal = categories.first(where: { $0.name == "Personal" })
        else {
            throw CheckError(message: "missing default categories")
        }

        let workTask = try store.memos.createTask(title: "Work task", scheduledDate: today, categoryId: work.id)
        let personalTask = try store.memos.createTask(title: "Personal task", scheduledDate: today, categoryId: personal.id)
        let loose = try store.memos.createNote(title: "Loose", scheduledDate: today, categoryId: nil)
        let done = try store.memos.createTask(title: "Done work", scheduledDate: today, categoryId: work.id)
        try store.memos.toggleCompleted(id: done.id)

        let all = try store.memos.fetchItems(for: today)
        try expectEqual(all.map(\.id), [workTask.id, personalTask.id, loose.id, done.id])

        let workOnly = try store.memos.fetchItems(for: today, categoryId: work.id)
        try expectEqual(workOnly.map(\.title), ["Work task", "Done work"])
        try expect(workOnly.contains(where: \.isCompleted))

        let personalOnly = try store.memos.fetchItems(for: today, categoryId: personal.id)
        try expectEqual(personalOnly.map(\.id), [personalTask.id])
        try expect(!personalOnly.contains(where: { $0.id == loose.id }))
    }
}
