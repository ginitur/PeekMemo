import Foundation
import PeekMeowCore

enum BackgroundFallbackTests {
    static func run() throws {
        try missingImageIsUnavailable()
        try presentImageStaysReadyAcrossANewStore()
        try systemAndSolidIgnoreAMissingFile()
        try lightSolidAsksForDarkText()
        try translucentSolidKeepsTheTheme()
        try fillAndFitAreTheOnlyContentModes()
        try removingTheCopyFallsBackWithoutDeletingTheSource()
    }

    static func missingImageIsUnavailable() throws {
        let scratch = try scratch()
        defer { try? FileManager.default.removeItem(at: scratch.root) }
        let store = BackgroundImageStore(directory: scratch.backgrounds)
        let status = store.imageStatus(
            mode: .image,
            filename: "background-AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE.jpg"
        )
        try expectEqual(status, .unavailable)
        try expectEqual(store.imageStatus(mode: .image, filename: nil), .empty)
        try expectEqual(store.imageStatus(mode: .image, filename: "/tmp/photo.jpg"), .empty)
    }

    static func presentImageStaysReadyAcrossANewStore() throws {
        let scratch = try scratch()
        defer { try? FileManager.default.removeItem(at: scratch.root) }
        let source = scratch.sources.appendingPathComponent("photo.png")
        try BackgroundImageFixtures.png.write(to: source)
        let filename = try BackgroundImageStore(directory: scratch.backgrounds).install(from: source)
        let reopened = BackgroundImageStore(directory: scratch.backgrounds)
        try expectEqual(reopened.imageStatus(mode: .image, filename: filename), .ready)
        try expect(reopened.existingFile(filename: filename) != nil)
    }

    static func systemAndSolidIgnoreAMissingFile() throws {
        let scratch = try scratch()
        defer { try? FileManager.default.removeItem(at: scratch.root) }
        let store = BackgroundImageStore(directory: scratch.backgrounds)
        try expectEqual(
            store.imageStatus(mode: .systemMaterial, filename: "background-missing.png"),
            .notApplicable
        )
        try expectEqual(store.imageStatus(mode: .solidColor, filename: nil), .notApplicable)
    }

    static func lightSolidAsksForDarkText() throws {
        let paper = RGBAColor(red: 0.965, green: 0.953, blue: 0.925)
        try expectEqual(
            BackgroundPresentation.contentColorScheme(mode: .solidColor, solid: paper, solidOpacity: 1),
            .light
        )
        let ink = RGBAColor(red: 0.08, green: 0.08, blue: 0.09)
        try expectEqual(
            BackgroundPresentation.contentColorScheme(mode: .solidColor, solid: ink, solidOpacity: 0.90),
            .dark
        )
        try expectEqual(
            BackgroundPresentation.contentColorScheme(mode: .systemMaterial, solid: paper, solidOpacity: 1),
            nil
        )
        try expectEqual(
            BackgroundPresentation.contentColorScheme(mode: .image, solid: paper, solidOpacity: 1),
            nil
        )
    }

    static func translucentSolidKeepsTheTheme() throws {
        let paper = RGBAColor(red: 1, green: 1, blue: 1)
        try expectEqual(
            BackgroundPresentation.contentColorScheme(mode: .solidColor, solid: paper, solidOpacity: 0.40),
            nil
        )
        let mid = RGBAColor(red: 0.70, green: 0.70, blue: 0.70)
        try expectEqual(
            BackgroundPresentation.contentColorScheme(mode: .solidColor, solid: mid, solidOpacity: 1),
            nil
        )
    }

    static func fillAndFitAreTheOnlyContentModes() throws {
        try expectEqual(BackgroundImageContentMode.allCases, [.fill, .fit])
        try expectEqual(BackgroundImageContentMode.fill.rawValue, "fill")
        try expectEqual(BackgroundImageContentMode.fit.rawValue, "fit")
        try expectEqual(BackgroundImageContentMode(rawValue: "stretch"), nil)
    }

    static func removingTheCopyFallsBackWithoutDeletingTheSource() throws {
        let scratch = try scratch()
        defer { try? FileManager.default.removeItem(at: scratch.root) }
        let source = scratch.sources.appendingPathComponent("photo.jpg")
        try BackgroundImageFixtures.jpeg.write(to: source)
        let store = BackgroundImageStore(directory: scratch.backgrounds)
        let filename = try store.install(from: source)
        try expect(store.removeManaged(filename: filename))
        try expectEqual(store.imageStatus(mode: .image, filename: filename), .unavailable)
        try expectEqual(try Data(contentsOf: source), BackgroundImageFixtures.jpeg)
        let isolated = try PreferencesTestSupport.isolate()
        defer { PreferencesTestSupport.finish(isolated.defaults, name: isolated.name) }
        let preferences = PreferencesStore(defaults: isolated.defaults)
        preferences.save(AppearancePreferences(
            backgroundMode: .systemMaterial,
            backgroundImageFilename: nil
        ))
        let loaded = preferences.load()
        try expectEqual(loaded.backgroundMode, .systemMaterial)
        try expectEqual(loaded.backgroundImageFilename, nil)
    }

    private struct Scratch {
        var root: URL
        var sources: URL
        var backgrounds: URL
    }

    private static func scratch() throws -> Scratch {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("PeekMeowFallback-\(UUID().uuidString)", isDirectory: true)
        let sources = root.appendingPathComponent("Sources", isDirectory: true)
        let backgrounds = root.appendingPathComponent("Backgrounds", isDirectory: true)
        try FileManager.default.createDirectory(at: sources, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: backgrounds, withIntermediateDirectories: true)
        try expect(!root.path.contains("Application Support"))
        return Scratch(root: root, sources: sources, backgrounds: backgrounds)
    }
}
