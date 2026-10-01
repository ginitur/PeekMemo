import Foundation
import PeekMemoCore

enum CategoryRepositoryTests {
    static func run() throws {
        try createsRenamesArchivesAndReorders()
        try missingCategoryThrows()
        try archiveKeepsMemoItems()
    }

    static func createsRenamesArchivesAndReorders() throws {
        let scratch = try PersistenceTestSupport.makeScratch()
        defer { PersistenceTestSupport.remove(scratch) }
        let store = try PersistenceTestSupport.open(scratch)
        let created = try store.categories.createCategory(name: "Errands")
        try expectEqual(created.sortOrder, 2)
        try store.categories.renameCategory(id: created.id, name: "Errands")
        var visible = try store.categories.fetchCategories()
        try expectEqual(visible.map(\.name), ["Work", "Personal", "Errands"])

        let work = visible[0]
        let personal = visible[1]
        try store.categories.reorderCategories([personal.id, created.id, work.id])
        visible = try store.categories.fetchCategories()
        try expectEqual(visible.map(\.name), ["Personal", "Errands", "Work"])
        try expectEqual(visible.map(\.sortOrder), [0, 1, 2])

        try store.categories.archiveCategory(id: created.id)
        try expectEqual(try store.categories.fetchCategories().map(\.name), ["Personal", "Work"])
        let archived = try store.categories.fetchCategories(includingArchived: true)
        try expect(archived.contains(where: { $0.id == created.id && $0.isArchived }))
    }

    static func missingCategoryThrows() throws {
        let scratch = try PersistenceTestSupport.makeScratch()
        defer { PersistenceTestSupport.remove(scratch) }
        let store = try PersistenceTestSupport.open(scratch)
        let missing = UUID()
        do {
            try store.categories.renameCategory(id: missing, name: "Nope")
            try expect(false, "rename of a missing category should throw")
        } catch let error as PersistenceError {
            try expectEqual(error, .notFound(missing))
        }
    }

    static func archiveKeepsMemoItems() throws {
        let scratch = try PersistenceTestSupport.makeScratch()
        defer { PersistenceTestSupport.remove(scratch) }
        let store = try PersistenceTestSupport.open(scratch)
        let work = try store.categories.fetchCategories().first { $0.name == "Work" }
        let workID = try expectCategory(work).id
        let task = try store.memos.createTask(
            title: "Keep me",
            scheduledDate: PersistenceTestSupport.today(),
            categoryId: workID
        )
        try store.categories.archiveCategory(id: workID)
        let visible = try store.categories.fetchCategories()
        try expect(visible.allSatisfy { $0.id != workID })
        let items = try store.memos.fetchItems(for: PersistenceTestSupport.today())
        try expectEqual(items.map(\.id), [task.id])
        try expectEqual(items.first?.categoryId, Optional(workID))
    }

    static func expectCategory(_ category: PeekMemoCore.Category?) throws -> PeekMemoCore.Category {
        guard let category else {
            throw CheckError(message: "expected a category")
        }
        return category
    }
}
