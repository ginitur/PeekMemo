import Foundation
import PeekMemoCore

enum PersistenceTestSupport {
    struct Scratch {
        let directory: URL
        let path: String
    }

    static func makeScratch() throws -> Scratch {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PeekMemoTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let path = directory.appendingPathComponent(DatabaseLocation.fileName).path
        try expect(!path.contains("Application Support"), "tests must not touch Application Support")
        return Scratch(directory: directory, path: path)
    }

    static func remove(_ scratch: Scratch) {
        try? FileManager.default.removeItem(at: scratch.directory)
    }

    static func open(_ scratch: Scratch) throws -> MemoStore {
        try MemoStore.open(path: scratch.path)
    }

    static func today() -> Date {
        DailyView.startOfDay(Date())
    }

    static func day(_ offset: Int, from day: Date = today()) -> Date {
        DailyView.shiftDay(day, by: offset)
    }
}
