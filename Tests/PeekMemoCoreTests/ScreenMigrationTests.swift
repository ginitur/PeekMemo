import CoreGraphics
import PeekMemoCore

enum ScreenMigrationTests {
    static func run() throws {
        try matchingDisplayIsKept()
        try missingDisplayMovesToMain()
        try cloakFlagClearsWhenMainScreenHasNoNotch()
        try pointPicksContainingScreen()
    }

    static func matchingDisplayIsKept() throws {
        let saved = DisplayPlacement(displayIdentifier: "ext-1", edge: .left, offset: 80)
        let result = ScreenMigration.resolve(
            saved: saved,
            screens: [Fixtures.external, Fixtures.notched],
            mainScreenID: "notch-1"
        )
        try expectEqual(result.placement.displayIdentifier, "ext-1")
        try expectEqual(result.placement.edge, .left)
        try expect(result.screen?.identifier == "ext-1")
    }

    static func missingDisplayMovesToMain() throws {
        let saved = DisplayPlacement(displayIdentifier: "gone", edge: .right, offset: 40)
        let result = ScreenMigration.resolve(
            saved: saved,
            screens: [Fixtures.external, Fixtures.notched],
            mainScreenID: "notch-1"
        )
        try expectEqual(result.placement.displayIdentifier, "notch-1")
        try expectEqual(result.placement.edge, .right)
        try expectEqual(result.placement.offset, 40)
        try expect(result.screen?.identifier == "notch-1")
    }

    static func cloakFlagClearsWhenMainScreenHasNoNotch() throws {
        let saved = DisplayPlacement(
            displayIdentifier: "gone",
            edge: .top,
            offset: 10,
            isNotchCloak: true
        )
        let result = ScreenMigration.resolve(
            saved: saved,
            screens: [Fixtures.external],
            mainScreenID: "ext-1"
        )
        try expect(!result.placement.isNotchCloak)
    }

    static func pointPicksContainingScreen() throws {
        let left = ScreenGeometry(
            identifier: "left",
            frame: CGRect(x: 0, y: 0, width: 1000, height: 800),
            visibleFrame: CGRect(x: 0, y: 0, width: 1000, height: 780)
        )
        let right = ScreenGeometry(
            identifier: "right",
            frame: CGRect(x: 1000, y: 0, width: 1920, height: 1080),
            visibleFrame: CGRect(x: 1000, y: 0, width: 1920, height: 1055)
        )
        let hit = ScreenMigration.screenContaining(
            point: CGPoint(x: 1400, y: 400),
            screens: [left, right]
        )
        try expect(hit?.identifier == "right")
    }
}
