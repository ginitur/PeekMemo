import Foundation

struct CheckError: Error, CustomStringConvertible {
    var message: String
    var description: String { message }
}

func expect(
    _ condition: @autoclosure () -> Bool,
    _ message: String = "expectation failed",
    file: String = #fileID,
    line: Int = #line
) throws {
    if !condition() {
        throw CheckError(message: "\(file):\(line) \(message)")
    }
}

func expectEqual<T: Equatable>(
    _ actual: T,
    _ expected: T,
    file: String = #fileID,
    line: Int = #line
) throws {
    try expect(actual == expected, "\(actual) != \(expected)", file: file, line: line)
}

@main
enum PeekMemoCoreTestsMain {
    static func main() {
        let suites: [(String, () throws -> Void)] = [
            ("EdgeGeometry", EdgeGeometryTests.run),
            ("NotchGeometry", NotchGeometryTests.run),
            ("ScreenMigration", ScreenMigrationTests.run),
            ("HoverEngine", HoverEngineTests.run),
            ("HoverRegion", HoverRegionTests.run),
            ("PanelAnimator", PanelAnimatorTests.run),
            ("AnchorPersistence", AnchorPersistenceTests.run),
            ("CornerClampAnchor", CornerClampAnchorTests.run),
            ("ColorSerialization", ColorSerializationTests.run),
        ]

        var failed = 0
        for (name, body) in suites {
            do {
                try body()
                print("ok   \(name)")
            } catch {
                failed += 1
                print("FAIL \(name): \(error)")
            }
        }

        if failed > 0 {
            print("\(failed) suite(s) failed")
            Foundation.exit(1)
        }
        print("all suites passed")
    }
}
