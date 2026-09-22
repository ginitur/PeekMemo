import Foundation
import PeekMemoCore

enum CategorySelectionStateTests {
    static func run() throws {
        try allClearsSelection()
        try workSelectsThatCategory()
        try menuChoiceNeverPins()
        try openingMenuDoesNotPinHover()
    }

    static func allClearsSelection() throws {
        var selection = CategorySelectionState(selectedCategoryID: UUID())
        selection.selectAll()
        try expect(selection.showsAll)
        try expect(selection.selectedCategoryID == nil)
        try expect(!selection.pinned)
    }

    static func workSelectsThatCategory() throws {
        var selection = CategorySelectionState()
        let work = UUID()
        selection.selectCategory(work)
        try expectEqual(selection.selectedCategoryID, work)
        try expect(!selection.showsAll)
        try expect(!selection.pinned)
    }

    static func menuChoiceNeverPins() throws {
        var selection = CategorySelectionState()
        let work = UUID()
        selection.applyMenuChoice(work)
        try expectEqual(selection.selectedCategoryID, work)
        try expect(!selection.pinned)
        selection.applyMenuChoice(nil)
        try expect(selection.selectedCategoryID == nil)
        try expect(!selection.pinned)
    }

    static func openingMenuDoesNotPinHover() throws {
        var engine = HoverEngine(phase: .expanded, pointerInside: true)
        var selection = CategorySelectionState()
        let began = engine.handle(.beginInteraction)
        try expectEqual(began, .cancelTimers)
        try expect(!engine.isPinned)
        selection.selectCategory(UUID())
        let ended = engine.handle(.endInteraction)
        try expectEqual(ended, .none)
        try expectEqual(engine.phase, .expanded)
        try expect(!engine.isPinned)
        try expect(!selection.pinned)
    }
}
