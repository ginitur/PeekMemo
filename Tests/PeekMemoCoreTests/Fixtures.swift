import CoreGraphics
import PeekMemoCore

enum Fixtures {
    /// A typical external display with a menu bar and no notch.
    static let external = ScreenGeometry(
        identifier: "ext-1",
        frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
        visibleFrame: CGRect(x: 0, y: 0, width: 1920, height: 1055),
        safeAreaInsets: .zero
    )

    /// Synthetic notched laptop. Numbers are a test fixture, not a product model.
    static let notched = ScreenGeometry(
        identifier: "notch-1",
        frame: CGRect(x: 0, y: 0, width: 1512, height: 982),
        visibleFrame: CGRect(x: 0, y: 0, width: 1512, height: 944),
        safeAreaInsets: EdgeInsetsLTRB(top: 38),
        auxiliaryTopLeft: CGRect(x: 0, y: 944, width: 620, height: 38),
        auxiliaryTopRight: CGRect(x: 892, y: 944, width: 620, height: 38)
    )

    /// Dock occupying the right edge of an otherwise ordinary display.
    static let dockRight = ScreenGeometry(
        identifier: "dock-right",
        frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
        visibleFrame: CGRect(x: 0, y: 0, width: 1372, height: 875),
        safeAreaInsets: .zero
    )
}
