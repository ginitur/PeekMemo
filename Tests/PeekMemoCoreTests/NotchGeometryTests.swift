import CoreGraphics
import PeekMemoCore

enum NotchGeometryTests {
    static func run() throws {
        try notchedScreenReportsRegionFromAuxiliaryAreas()
        try displayWithoutAuxiliaryAreasHasNoNotch()
        try droppingOnNotchEntersCloakInsteadOfPushingAside()
        try topEdgeAwayFromNotchStaysANormalTab()
        try cloakCanBeDisabled()
        try expandedCloakPanelOpensDownwardFromNotch()
    }

    static func notchedScreenReportsRegionFromAuxiliaryAreas() throws {
        guard let notch = NotchGeometry.region(on: Fixtures.notched) else {
            throw CheckError(message: "expected a notch region")
        }
        try expectEqual(notch.frame.minX, 620)
        try expectEqual(notch.frame.maxX, 892)
        try expectEqual(notch.frame.width, 272)
        try expectEqual(notch.frame.maxY, Fixtures.notched.frame.maxY)
        try expectEqual(notch.frame.height, Fixtures.notched.safeAreaInsets.top)
    }

    static func displayWithoutAuxiliaryAreasHasNoNotch() throws {
        try expect(NotchGeometry.region(on: Fixtures.external) == nil)
        try expect(!Fixtures.external.hasNotch)
    }

    static func droppingOnNotchEntersCloakInsteadOfPushingAside() throws {
        let stack: CGFloat = 96
        let offset = NotchGeometry.cloakOffset(stackLength: stack, screen: Fixtures.notched)
        let placement = EdgeGeometry.collapsedPlacement(
            screen: Fixtures.notched,
            edge: .top,
            offset: offset,
            stackLength: stack,
            allowNotchCloak: true
        )
        try expect(placement.isNotchCloak)
        try expectEqual(placement.edge, .top)
        guard let notch = NotchGeometry.region(on: Fixtures.notched) else {
            throw CheckError(message: "expected a notch region")
        }
        try expectEqual(placement.frame.minY, notch.frame.minY - LayoutMetrics.hoverHitThickness)
        try expectEqual(placement.frame.maxY, notch.frame.maxY)
    }

    static func topEdgeAwayFromNotchStaysANormalTab() throws {
        let placement = EdgeGeometry.collapsedPlacement(
            screen: Fixtures.notched,
            edge: .top,
            offset: 20,
            stackLength: 96,
            allowNotchCloak: true
        )
        try expect(!placement.isNotchCloak)
        try expectEqual(placement.frame.maxY, Fixtures.notched.visibleFrame.maxY)
        try expectEqual(placement.frame.height, LayoutMetrics.hoverHitThickness)
    }

    static func cloakCanBeDisabled() throws {
        let offset = NotchGeometry.cloakOffset(stackLength: 96, screen: Fixtures.notched)
        let placement = EdgeGeometry.collapsedPlacement(
            screen: Fixtures.notched,
            edge: .top,
            offset: offset,
            stackLength: 96,
            allowNotchCloak: false
        )
        try expect(!placement.isNotchCloak)
    }

    static func expandedCloakPanelOpensDownwardFromNotch() throws {
        let stack: CGFloat = 96
        let offset = NotchGeometry.cloakOffset(stackLength: stack, screen: Fixtures.notched)
        let collapsed = EdgeGeometry.collapsedPlacement(
            screen: Fixtures.notched,
            edge: .top,
            offset: offset,
            stackLength: stack
        )
        let expanded = EdgeGeometry.expandedFrame(
            collapsed: collapsed,
            screen: Fixtures.notched,
            panelSize: CGSize(width: 280, height: 360)
        )
        guard let notch = NotchGeometry.region(on: Fixtures.notched) else {
            throw CheckError(message: "expected a notch region")
        }
        try expectEqual(expanded.maxY, notch.frame.minY)
        try expectEqual(expanded.height, 360)
    }
}
