import CoreGraphics
import PeekMemoCore

enum Fixtures {
    /// A typical external display with a menu bar.
    static let external = ScreenGeometry(
        identifier: "ext-1",
        frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
        visibleFrame: CGRect(x: 0, y: 0, width: 1920, height: 1055)
    )

    /// A second built-in display, used when a saved display is missing.
    static let builtin = ScreenGeometry(
        identifier: "builtin-1",
        frame: CGRect(x: 0, y: 0, width: 1512, height: 982),
        visibleFrame: CGRect(x: 0, y: 0, width: 1512, height: 944)
    )

    /// Dock occupying the right edge of an otherwise ordinary display.
    static let dockRight = ScreenGeometry(
        identifier: "dock-right",
        frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
        visibleFrame: CGRect(x: 0, y: 0, width: 1372, height: 875)
    )
}
