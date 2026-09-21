import CoreGraphics
import PeekMemoCore

enum HoverRegionTests {
    static func run() throws {
        try unionCoversTabAndPanel()
        try paddingCoversAnimationGap()
        try collapsedRegionDoesNotIncludePanel()
    }

    static func unionCoversTabAndPanel() throws {
        let tab = CGRect(x: 1498, y: 400, width: 14, height: 96)
        let panel = CGRect(x: 1238, y: 256, width: 260, height: 240)
        let region = HoverRegion.frame(collapsed: tab, expanded: panel, phase: .expanded, padding: 0)
        try expect(region.contains(CGPoint(x: 1500, y: 450)))
        try expect(region.contains(CGPoint(x: 1300, y: 350)))
        try expect(region.contains(CGPoint(x: 1490, y: 420)))
    }

    static func paddingCoversAnimationGap() throws {
        let tab = CGRect(x: 100, y: 0, width: 14, height: 96)
        let panel = CGRect(x: 114, y: 0, width: 260, height: 228)
        let gapPoint = CGPoint(x: 113, y: 40)
        try expect(
            HoverRegion.contains(
                gapPoint,
                collapsed: tab,
                expanded: panel,
                phase: .expanded,
                padding: 6
            )
        )
    }

    static func collapsedRegionDoesNotIncludePanel() throws {
        let tab = CGRect(x: 1498, y: 400, width: 14, height: 96)
        let panel = CGRect(x: 1238, y: 256, width: 260, height: 240)
        try expect(
            !HoverRegion.contains(
                CGPoint(x: 1300, y: 350),
                collapsed: tab,
                expanded: panel,
                phase: .collapsed,
                padding: 0
            )
        )
    }
}
