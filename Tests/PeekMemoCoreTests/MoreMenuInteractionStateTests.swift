import PeekMemoCore

enum MoreMenuInteractionStateTests {
    static func run() throws {
        try narrowPanelHidesCustomChips()
        try widePanelShowsTwoChips()
        try bottomNavHasFixedHeight()
    }

    static func narrowPanelHidesCustomChips() throws {
        try expectEqual(BottomNavLayout.visibleCustomListCount(panelWidth: 200), 0)
    }

    static func widePanelShowsTwoChips() throws {
        try expectEqual(BottomNavLayout.visibleCustomListCount(panelWidth: 300), 2)
    }

    static func bottomNavHasFixedHeight() throws {
        try expect(BottomNavLayout.height >= 32)
    }
}
