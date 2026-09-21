import CoreGraphics
import PeekMemoCore

enum NotchContainedFrameTests {
    static func run() throws {
        try collapsedIsFullyInsideNotchRect()
        try collapsedDoesNotExtendBelowNotch()
        try expandedKeepsTopInNotchAndGrowsDown()
    }

    static func collapsedIsFullyInsideNotchRect() throws {
        guard let notch = NotchGeometry.region(on: Fixtures.notched) else {
            throw CheckError(message: "expected notch")
        }
        let frame = NotchGeometry.collapsedWindowFrame(for: notch)
        try expect(NotchGeometry.isFullyContained(frame, in: notch.frame))
        try expectEqual(frame, notch.frame)
        let placement = EdgeGeometry.collapsedPlacement(
            screen: Fixtures.notched,
            edge: .top,
            offset: NotchGeometry.cloakOffset(stackLength: 56, screen: Fixtures.notched),
            stackLength: 56
        )
        try expect(placement.isNotchCloak)
        try expect(NotchGeometry.isFullyContained(placement.frame, in: notch.frame))
    }

    static func collapsedDoesNotExtendBelowNotch() throws {
        guard let notch = NotchGeometry.region(on: Fixtures.notched) else {
            throw CheckError(message: "expected notch")
        }
        let frame = NotchGeometry.collapsedWindowFrame(for: notch)
        try expect(frame.minY >= notch.frame.minY)
        try expect(frame.maxY <= notch.frame.maxY)
    }

    static func expandedKeepsTopInNotchAndGrowsDown() throws {
        let collapsed = EdgeGeometry.collapsedPlacement(
            screen: Fixtures.notched,
            edge: .top,
            offset: NotchGeometry.cloakOffset(stackLength: 56, screen: Fixtures.notched),
            stackLength: 56
        )
        let expanded = EdgeGeometry.expandedFrame(
            collapsed: collapsed,
            screen: Fixtures.notched,
            panelSize: CGSize(width: 260, height: 228)
        )
        guard let notch = NotchGeometry.region(on: Fixtures.notched) else {
            throw CheckError(message: "expected notch")
        }
        try expectEqual(expanded.maxY, notch.frame.maxY)
        try expect(expanded.minY < notch.frame.minY)
        try expect(expanded.height > notch.frame.height)
    }
}
