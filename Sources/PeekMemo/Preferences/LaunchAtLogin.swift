import ServiceManagement

/// Login item via `SMAppService.mainApp` only. Never a LaunchAgent or a shell script.
enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Quiet when the item is simply on or off. Set when the system needs a person.
    static var statusMessage: String? {
        switch SMAppService.mainApp.status {
        case .enabled, .notRegistered:
            nil
        case .requiresApproval:
            "macOS is waiting for approval in System Settings → General → Login Items."
        case .notFound:
            "Login Items can only be changed from an installed PeekMemo app. This build is not registered with the system."
        @unknown default:
            "Login Items returned an unrecognized status."
        }
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
