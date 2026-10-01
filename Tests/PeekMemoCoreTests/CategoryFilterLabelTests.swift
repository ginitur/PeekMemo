import Foundation
import PeekMemoCore

enum CategoryFilterLabelTests {
    static func run() throws {
        try expectEqual(CategoryFilterLabel.title(selectedName: nil), "All Tasks")
        try expectEqual(CategoryFilterLabel.title(selectedName: "  "), "All Tasks")
        try expectEqual(CategoryFilterLabel.title(selectedName: "Work"), "Work")
        try expectEqual(CategoryFilterLabel.title(selectedName: "Personal"), "Personal")
        try expect(CategoryFilterLabel.allTasks != "All")
    }
}
