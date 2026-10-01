import AppKit
import CoreGraphics
import PeekMeowCore

/// AppKit adapter. The only type that should read `NSScreen`.
enum ScreenManager {
    static func snapshot(from screen: NSScreen) -> ScreenGeometry {
        ScreenGeometry(
            identifier: displayIdentifier(for: screen),
            frame: screen.frame,
            visibleFrame: screen.visibleFrame
        )
    }

    static func allSnapshots() -> [ScreenGeometry] {
        NSScreen.screens.map(snapshot(from:))
    }

    static func mainSnapshot() -> ScreenGeometry? {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            return nil
        }
        return snapshot(from: screen)
    }

    static func displayIdentifier(for screen: NSScreen) -> String {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        if let number = screen.deviceDescription[key] as? NSNumber {
            return String(number.uint32Value)
        }
        return screen.localizedName
    }
}
