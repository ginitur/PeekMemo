import AppKit
import PeekMemoCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static let shared = AppDelegate()

    private var panelController: PanelController?
    private var statusItemController: StatusItemController?
    private var preferencesWindow: PreferencesWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let appState = AppState()
        let preferences = PreferencesModel(appState: appState)
        let controller = PanelController(appState: appState, preferences: preferences)
        let settings = PreferencesWindowController(model: preferences)
        preferences.onChange = { [weak controller, weak settings] in
            controller?.applyPreferences()
            settings?.applyTheme()
        }
        panelController = controller
        preferencesWindow = settings
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
            },
            onOpenSettings: { [weak self] in
                self?.preferencesWindow?.show()
            }
        )
        controller.showRestoredOrDefault()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        panelController?.showRestoredOrDefault()
        return false
    }
}
