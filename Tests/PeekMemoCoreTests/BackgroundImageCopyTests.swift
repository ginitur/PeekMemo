import Foundation
import PeekMemoCore

enum BackgroundImageCopyTests {
    static func run() throws {
        try recognizesCommonFormats()
        try copiesIntoTheStoreAndLeavesTheSource()
        try replaceKeepsTheSourceAndDropsOnlyTheOldCopy()
        try failedCopyKeepsThePreviousFile()
        try removeDoesNotDeleteTheOriginal()
        try rejectsTraversalAndUnsupportedFiles()
        try directoryContainsOnlyTheManagedCopy()
    }

    static func recognizesCommonFormats() throws {
        try expectEqual(BackgroundImageValidator.kind(header: BackgroundImageFixtures.png), .png)
        try expectEqual(BackgroundImageValidator.kind(header: BackgroundImageFixtures.jpeg), .jpeg)
        try expectEqual(BackgroundImageValidator.kind(header: BackgroundImageFixtures.heic), .heic)
        try expectEqual(BackgroundImageValidator.kind(header: BackgroundImageFixtures.tiff), .tiff)
        try expectEqual(BackgroundImageValidator.kind(header: BackgroundImageFixtures.webp), .webp)
        try expectEqual(BackgroundImageValidator.kind(header: Data("not an image".utf8)), nil)
    }

    static func copiesIntoTheStoreAndLeavesTheSource() throws {
        let scratch = try makeScratch()
        defer { remove(scratch) }
        let source = try BackgroundImageFixtures.write(BackgroundImageFixtures.png, named: "photo.png", in: scratch.sources)
        let store = BackgroundImageStore(directory: scratch.backgrounds)
        let filename = try store.install(from: source)
        try expect(filename.hasPrefix("background-"))
        try expect(filename.hasSuffix(".png"))
        try expect(!filename.contains("/"))
        try expect(!filename.contains("photo"))
        let copied = try requireFile(store.existingFile(filename: filename))
        try expectEqual(try Data(contentsOf: copied), BackgroundImageFixtures.png)
        try expectEqual(try Data(contentsOf: source), BackgroundImageFixtures.png)
        try expect(FileManager.default.fileExists(atPath: source.path))
        try expect(!copied.path.contains("Downloads"))
        try expect(copied.path.contains("Backgrounds"))
    }

    static func replaceKeepsTheSourceAndDropsOnlyTheOldCopy() throws {
        let scratch = try makeScratch()
        defer { remove(scratch) }
        let firstSource = try BackgroundImageFixtures.write(BackgroundImageFixtures.png, named: "first.png", in: scratch.sources)
        let secondSource = try BackgroundImageFixtures.write(BackgroundImageFixtures.jpeg, named: "second.jpg", in: scratch.sources)
        let store = BackgroundImageStore(directory: scratch.backgrounds)
        let first = try store.install(from: firstSource)
        let second = try store.install(from: secondSource)
        try expect(store.removeManaged(filename: first))
        try expectEqual(store.existingFile(filename: first), nil)
        let kept = try requireFile(store.existingFile(filename: second))
        try expectEqual(try Data(contentsOf: kept), BackgroundImageFixtures.jpeg)
        try expectEqual(try Data(contentsOf: firstSource), BackgroundImageFixtures.png)
        try expectEqual(try Data(contentsOf: secondSource), BackgroundImageFixtures.jpeg)
        let names = try FileManager.default.contentsOfDirectory(atPath: scratch.backgrounds.path)
        try expectEqual(names, [second])
    }

    static func failedCopyKeepsThePreviousFile() throws {
        let scratch = try makeScratch()
        defer { remove(scratch) }
        let source = try BackgroundImageFixtures.write(BackgroundImageFixtures.png, named: "photo.png", in: scratch.sources)
        let replacement = try BackgroundImageFixtures.write(BackgroundImageFixtures.jpeg, named: "next.jpg", in: scratch.sources)
        let store = BackgroundImageStore(directory: scratch.backgrounds)
        let first = try store.install(from: source)
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: scratch.backgrounds.path)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scratch.backgrounds.path)
        }
        do {
            _ = try store.install(from: replacement)
            throw CheckError(message: "copy into a read-only folder should fail")
        } catch let error as BackgroundImageError {
            try expectEqual(error, .copyFailed)
        }
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scratch.backgrounds.path)
        let kept = try requireFile(store.existingFile(filename: first))
        try expectEqual(try Data(contentsOf: kept), BackgroundImageFixtures.png)
        try expect(FileManager.default.fileExists(atPath: source.path))
        try expect(FileManager.default.fileExists(atPath: replacement.path))
    }

    static func removeDoesNotDeleteTheOriginal() throws {
        let scratch = try makeScratch()
        defer { remove(scratch) }
        let source = try BackgroundImageFixtures.write(BackgroundImageFixtures.heic, named: "camera.heic", in: scratch.sources)
        let store = BackgroundImageStore(directory: scratch.backgrounds)
        let filename = try store.install(from: source)
        try expect(filename.hasSuffix(".heic"))
        try expect(store.removeManaged(filename: filename))
        try expectEqual(store.existingFile(filename: filename), nil)
        try expectEqual(try Data(contentsOf: source), BackgroundImageFixtures.heic)
        try expect(!store.removeManaged(filename: "../\(source.lastPathComponent)"))
        try expect(!store.removeManaged(filename: source.path))
        try expect(FileManager.default.fileExists(atPath: source.path))
    }

    static func rejectsTraversalAndUnsupportedFiles() throws {
        let scratch = try makeScratch()
        defer { remove(scratch) }
        let store = BackgroundImageStore(directory: scratch.backgrounds)
        let text = try BackgroundImageFixtures.write(Data("hello".utf8), named: "notes.png", in: scratch.sources)
        let previous = try store.install(from: BackgroundImageFixtures.write(BackgroundImageFixtures.png, named: "ok.png", in: scratch.sources))
        do {
            _ = try store.install(from: text)
            throw CheckError(message: "a text file with a png name should be rejected")
        } catch let error as BackgroundImageError {
            try expectEqual(error, .unsupported)
        }
        try expect(store.existingFile(filename: previous) != nil)
        try expect(!store.removeManaged(filename: "../../photo.png"))
        try expect(!store.removeManaged(filename: "photo.png"))
        try expect(FileManager.default.fileExists(atPath: text.path))
    }

    static func directoryContainsOnlyTheManagedCopy() throws {
        let scratch = try makeScratch()
        defer { remove(scratch) }
        let source = try BackgroundImageFixtures.write(BackgroundImageFixtures.tiff, named: "scan.tiff", in: scratch.sources)
        let store = BackgroundImageStore(directory: scratch.backgrounds)
        let filename = try store.install(from: source)
        try expect(filename.hasSuffix(".tiff"))
        let names = try FileManager.default.contentsOfDirectory(atPath: scratch.backgrounds.path)
        try expectEqual(names, [filename])
        try expect(names.allSatisfy { $0.hasPrefix("background-") })
        let reopened = BackgroundImageStore(directory: scratch.backgrounds)
        let again = try requireFile(reopened.existingFile(filename: filename))
        try expectEqual(try Data(contentsOf: again), BackgroundImageFixtures.tiff)
    }

    private struct Scratch {
        var root: URL
        var sources: URL
        var backgrounds: URL
    }

    private static func makeScratch() throws -> Scratch {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("PeekMemoBackground-\(UUID().uuidString)", isDirectory: true)
        let sources = root.appendingPathComponent("Sources", isDirectory: true)
        let backgrounds = root.appendingPathComponent("Backgrounds", isDirectory: true)
        try FileManager.default.createDirectory(at: sources, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: backgrounds, withIntermediateDirectories: true)
        try expect(!root.path.contains("Application Support"))
        return Scratch(root: root, sources: sources, backgrounds: backgrounds)
    }

    private static func remove(_ scratch: Scratch) {
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scratch.backgrounds.path)
        try? FileManager.default.removeItem(at: scratch.root)
    }

    private static func requireFile(_ url: URL?) throws -> URL {
        guard let url else { throw CheckError(message: "managed background file is missing") }
        return url
    }
}
