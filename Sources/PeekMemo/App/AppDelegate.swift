import AppKit
import PeekMemoCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static let shared = AppDelegate()

    private var panelController: PanelController?
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let controller = PanelController()
        panelController = controller
        statusItemController = StatusItemController(
            onShow: { [weak controller] in
                controller?.showRestoredOrDefault()
            },
            onHide: { [weak controller] in
                controller?.hide()
            },
            onReset: { [weak controller] in
                controller?.resetPosition()
            },
            onToggleHitRegions: { [weak controller] in
                #if DEBUG
                DebugFlags.showHitRegions.toggle()
                controller?.refreshChrome()
                #endif
            },
            onToggleNotchGeometry: { [weak controller] in
                #if DEBUG
                DebugFlags.showNotchGeometry.toggle()
                controller?.refreshChrome()
                #endif
            },
            onMoveToNotch: { [weak controller] in
                controller?.moveToNotchCloak()
            },
            onToggleAnchorGeometry: { [weak controller] in
                #if DEBUG
                DebugFlags.showAnchorGeometry.toggle()
                controller?.refreshChrome()
                #endif
            },
            onToggleInteractionRegions: { [weak controller] in
                #if DEBUG
                DebugFlags.showInteractionRegions.toggle()
                controller?.refreshChrome()
                #endif
            }
        )
        controller.showRestoredOrDefault()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        panelController?.showRestoredOrDefault()
        return false
    }
}
