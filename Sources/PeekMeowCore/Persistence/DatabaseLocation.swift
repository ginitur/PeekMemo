import Foundation

public enum DatabaseLocation: Sendable {
    public static let fileName = "PeekMeow.sqlite"

    /// `~/Library/Application Support/PeekMeow/PeekMeow.sqlite`
    public static func defaultDatabaseURL() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base.appendingPathComponent("PeekMeow", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(fileName)
    }
}
