import CoreGraphics
import PeekMemoCore

enum TopEdgeDragTests {
    static func run() throws {
        try liveDragAlongTopDoesNotCloak()
        try mouseUpOnNotchDoesCloak()
        try dragFromTopTowardRightCommitsRight()
        try dragFromTopTowardBottomUnsnapsThenSnaps()
    }

    static func liveDragAlongTopDoesNotCloak() throws {
        guard let notch = NotchGeometry.region(on: Fixtures.notched) else {
            throw CheckError(message: "expected notch")
        }
        let pointer = CGPoint(x: notch.frame.midX, y: Fixtures.notched.frame.maxY - 4)
        let live = EdgeGeometry.draggingPlacement(
            pointer: pointer,
            screen: Fixtures.notched,
            stackLength: 56,
            grabSize: CGSize(width: 56, height: 14)
        )
        try expect(!live.isNotchCloak)
        try expectEqual(live.edge, .top)
    }

    static func mouseUpOnNotchDoesCloak() throws {
        guard let notch = NotchGeometry.region(on: Fixtures.notched) else {
            throw CheckError(message: "expected notch")
        }
        let pointer = CGPoint(x: notch.frame.midX, y: Fixtures.notched.frame.maxY - 4)
        let committed = EdgeGeometry.committedPlacement(
            pointer: pointer,
            screen: Fixtures.notched,
            stackLength: 56
        )
        try expect(committed.isNotchCloak)
    }

    static func dragFromTopTowardRightCommitsRight() throws {
        let screen = Fixtures.external
        let pointer = CGPoint(x: screen.frame.maxX - 8, y: screen.frame.midY)
        let committed = EdgeGeometry.committedPlacement(
            pointer: pointer,
            screen: screen,
            stackLength: 56
        )
        try expectEqual(committed.edge, .right)
        try expect(!committed.isNotchCloak)
    }

    static func dragFromTopTowardBottomUnsnapsThenSnaps() throws {
        let screen = Fixtures.external
        let far = CGPoint(x: screen.frame.midX, y: screen.frame.midY)
        let live = EdgeGeometry.draggingPlacement(
            pointer: far,
            screen: screen,
            stackLength: 56,
            grabSize: CGSize(width: 40, height: 56)
        )
        try expect(!live.isSnapped)
        let committed = EdgeGeometry.committedPlacement(pointer: far, screen: screen, stackLength: 56)
        try expect(committed.isSnapped)
        try expect(committed.edge == .left || committed.edge == .right || committed.edge == .top || committed.edge == .bottom)
    }
}
