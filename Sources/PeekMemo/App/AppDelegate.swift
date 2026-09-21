import AppKit
import PeekMemoCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static let shared = AppDelegate()

    private var panelController: PanelController?
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItemController = StatusItemController()
        let controller = PanelController()
        panelController = controller
        controller.showCollapsed(
            edge: AppSettings.default.selectedEdge,
            offset: AppSettings.default.edgeOffset
        )
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        panelController?.showCollapsed(
            edge: AppSettings.default.selectedEdge,
            offset: AppSettings.default.edgeOffset
        )
        return false
    }
}
