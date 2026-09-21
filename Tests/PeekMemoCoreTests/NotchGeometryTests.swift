import CoreGraphics
import PeekMemoCore

enum NotchGeometryTests {
    static func run() throws {
        try notchedScreenReportsRegionFromAuxiliaryAreas()
        try regionAcceptsRawRectangles()
        try displayWithoutAuxiliaryAreasHasNoNotch()
        try droppingOnNotchEntersCloakInsteadOfPushingAside()
        try cloakWindowSitsOnUndersideNotInHousing()
        try topEdgeAwayFromNotchStaysANormalTab()
        try cloakCanBeDisabled()
        try expandedCloakPanelOpensDownwardFromNotch()
        try enterNotchFromTheLeft()
        try enterNotchFromTheRight()
        try dragOutOfNotchToTheLeft()
        try dragOutOfNotchToTheRight()
        try offsetClampOnNotchedTopEdge()
        try screenSizeChangeKeepsCloakOnDerivedNotch()
        try noCloakUIOnExternalDisplay()
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
        try expect(NotchGeometry.horizontalRange(on: Fixtures.notched) == 620...892)
    }

    static func regionAcceptsRawRectangles() throws {
        let notch = NotchGeometry.region(
            screenFrame: Fixtures.notched.frame,
            safeAreaInsets: Fixtures.notched.safeAreaInsets,
            auxiliaryTopLeft: Fixtures.notched.auxiliaryTopLeft,
            auxiliaryTopRight: Fixtures.notched.auxiliaryTopRight
        )
        try expect(notch != nil)
        try expectEqual(notch?.frame, NotchGeometry.region(on: Fixtures.notched)?.frame)
    }

    static func displayWithoutAuxiliaryAreasHasNoNotch() throws {
        try expect(NotchGeometry.region(on: Fixtures.external) == nil)
        try expect(!Fixtures.external.hasNotch)
        try expect(NotchGeometry.horizontalRange(on: Fixtures.external) == nil)
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
    }

    static func cloakWindowSitsOnUndersideNotInHousing() throws {
        let stack: CGFloat = 96
        let offset = NotchGeometry.cloakOffset(stackLength: stack, screen: Fixtures.notched)
        let placement = EdgeGeometry.collapsedPlacement(
            screen: Fixtures.notched,
            edge: .top,
            offset: offset,
            stackLength: stack
        )
        guard let notch = NotchGeometry.region(on: Fixtures.notched) else {
            throw CheckError(message: "expected a notch region")
        }
        let hit = NotchGeometry.undersideHitRect(for: notch)
        try expectEqual(placement.frame, hit)
        try expectEqual(placement.frame.maxY, notch.frame.minY)
        try expectEqual(placement.frame.height, LayoutMetrics.notchCloakHitThickness)
        try expect(placement.frame.maxY <= notch.frame.minY + 0.01)
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

    static func enterNotchFromTheLeft() throws {
        guard let notch = NotchGeometry.region(on: Fixtures.notched) else {
            throw CheckError(message: "expected a notch region")
        }
        let justInside = CGPoint(x: notch.frame.minX + 8, y: Fixtures.notched.frame.maxY - 4)
        let approaching = CGPoint(x: notch.frame.minX - 12, y: Fixtures.notched.frame.maxY - 4)
        let far = CGPoint(x: notch.frame.minX - 80, y: Fixtures.notched.frame.maxY - 4)

        try expect(NotchGeometry.pointerCommitsCloak(justInside, screen: Fixtures.notched))
        try expectEqual(NotchGeometry.cloakPull(pointer: justInside, screen: Fixtures.notched), 1)
        try expect(NotchGeometry.cloakPull(pointer: approaching, screen: Fixtures.notched) > 0)
        try expect(NotchGeometry.cloakPull(pointer: approaching, screen: Fixtures.notched) < 1)
        try expectEqual(NotchGeometry.cloakPull(pointer: far, screen: Fixtures.notched), 0)

        let live = EdgeGeometry.draggingPlacement(
            pointer: justInside,
            screen: Fixtures.notched,
            stackLength: 96,
            grabSize: CGSize(width: 96, height: 14)
        )
        try expect(live.isNotchCloak)
        try expect(abs(live.frame.midX - justInside.x) < 60)
        try expect(abs(live.frame.midX - notch.frame.midX) > 1)
    }

    static func enterNotchFromTheRight() throws {
        guard let notch = NotchGeometry.region(on: Fixtures.notched) else {
            throw CheckError(message: "expected a notch region")
        }
        let justInside = CGPoint(x: notch.frame.maxX - 8, y: Fixtures.notched.frame.maxY - 4)
        let approaching = CGPoint(x: notch.frame.maxX + 12, y: Fixtures.notched.frame.maxY - 4)

        try expect(NotchGeometry.pointerCommitsCloak(justInside, screen: Fixtures.notched))
        try expect(NotchGeometry.cloakPull(pointer: approaching, screen: Fixtures.notched) > 0)
        try expect(NotchGeometry.cloakPull(pointer: approaching, screen: Fixtures.notched) < 1)

        let committed = EdgeGeometry.committedPlacement(
            pointer: justInside,
            screen: Fixtures.notched,
            stackLength: 96
        )
        try expect(committed.isNotchCloak)
        try expectEqual(committed.frame, NotchGeometry.undersideHitRect(for: notch))
    }

    static func dragOutOfNotchToTheLeft() throws {
        guard let notch = NotchGeometry.region(on: Fixtures.notched) else {
            throw CheckError(message: "expected a notch region")
        }
        let outside = CGPoint(x: notch.frame.minX - 80, y: Fixtures.notched.frame.maxY - 4)
        let live = EdgeGeometry.draggingPlacement(
            pointer: outside,
            screen: Fixtures.notched,
            stackLength: 96,
            grabSize: CGSize(width: 96, height: 14)
        )
        try expect(!live.isNotchCloak)
        try expectEqual(live.edge, .top)

        let committed = EdgeGeometry.committedPlacement(
            pointer: outside,
            screen: Fixtures.notched,
            stackLength: 96
        )
        try expect(!committed.isNotchCloak)
        try expectEqual(committed.edge, .top)
    }

    static func dragOutOfNotchToTheRight() throws {
        guard let notch = NotchGeometry.region(on: Fixtures.notched) else {
            throw CheckError(message: "expected a notch region")
        }
        let outside = CGPoint(x: notch.frame.maxX + 80, y: Fixtures.notched.frame.maxY - 4)
        let committed = EdgeGeometry.committedPlacement(
            pointer: outside,
            screen: Fixtures.notched,
            stackLength: 96
        )
        try expect(!committed.isNotchCloak)
        try expectEqual(committed.edge, .top)
    }

    static func offsetClampOnNotchedTopEdge() throws {
        let huge = EdgeGeometry.clampOffset(
            10_000,
            edge: .top,
            screen: Fixtures.notched,
            stackLength: 96
        )
        try expectEqual(huge, Fixtures.notched.visibleFrame.width - 96)
        let negative = EdgeGeometry.clampOffset(
            -20,
            edge: .top,
            screen: Fixtures.notched,
            stackLength: 96
        )
        try expectEqual(negative, 0)
    }

    static func screenSizeChangeKeepsCloakOnDerivedNotch() throws {
        let stored = DisplayPlacement(
            displayIdentifier: "notch-1",
            edge: .top,
            offset: 10,
            isNotchCloak: true
        )
        let larger = ScreenGeometry(
            identifier: "notch-1",
            frame: CGRect(x: 0, y: 0, width: 1728, height: 1117),
            visibleFrame: CGRect(x: 0, y: 0, width: 1728, height: 1079),
            safeAreaInsets: EdgeInsetsLTRB(top: 38),
            auxiliaryTopLeft: CGRect(x: 0, y: 1079, width: 720, height: 38),
            auxiliaryTopRight: CGRect(x: 1008, y: 1079, width: 720, height: 38)
        )
        let placement = EdgeGeometry.placement(from: stored, screen: larger, stackLength: 96)
        try expect(placement.isNotchCloak)
        guard let notch = NotchGeometry.region(on: larger) else {
            throw CheckError(message: "expected notch on resized screen")
        }
        try expectEqual(placement.frame, NotchGeometry.undersideHitRect(for: notch))
        try expectEqual(notch.frame.minX, 720)
        try expectEqual(notch.frame.maxX, 1008)
    }

    static func noCloakUIOnExternalDisplay() throws {
        let stored = DisplayPlacement(
            displayIdentifier: "ext-1",
            edge: .top,
            offset: 200,
            isNotchCloak: true
        )
        let placement = EdgeGeometry.placement(from: stored, screen: Fixtures.external, stackLength: 96)
        try expect(!placement.isNotchCloak)
        try expectEqual(placement.edge, .top)
    }
}
