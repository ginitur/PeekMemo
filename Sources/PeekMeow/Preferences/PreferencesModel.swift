import AppKit
import Observation
import PeekMeowCore
import UniformTypeIdentifiers

enum SettingsPage: String, CaseIterable {
    case general
    case appearance
    case behavior
}

/// Owns appearance preferences and pushes them to the panel. Views do not touch UserDefaults.
@MainActor
@Observable
final class PreferencesModel {
    private let store: PreferencesStore
    private let backgroundImages: BackgroundImageStore
    let appState: AppState
    var snapshot: AppearancePreferences
    var page: SettingsPage = .general
    var launchAtLoginMessage: String?
    var backgroundMessage: String?
    var categoryNameDrafts: [UUID: String] = [:]
    var onChange: (() -> Void)?

    @ObservationIgnored nonisolated(unsafe) private var systemObservers: [any NSObjectProtocol] = []

    init(
        store: PreferencesStore = PreferencesStore(),
        appState: AppState,
        backgroundImages: BackgroundImageStore = BackgroundImageStore(
            directory: BackgroundImageStore.applicationSupportDirectory()
        )
    ) {
        self.store = store
        self.backgroundImages = backgroundImages
        self.appState = appState
        snapshot = store.load()
        refreshLaunchAtLoginFromSystem()
        observeSystemChanges()
    }

    deinit {
        for observer in systemObservers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            DistributedNotificationCenter.default().removeObserver(observer)
        }
    }

    var reducesMotion: Bool {
        MotionPolicy.shouldReduce(
            preference: snapshot.reduceMotion,
            systemEnabled: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        )
    }

    var windowAppearance: NSAppearance? {
        switch snapshot.theme {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }

    func movementDuration(_ duration: TimeInterval) -> TimeInterval {
        MotionPolicy.movementDuration(duration, reduce: reducesMotion)
    }

    func update(_ body: (inout AppearancePreferences) -> Void) {
        var next = snapshot
        body(&next)
        snapshot = next.clamped()
        store.save(snapshot)
        backgroundMessage = nil
        onChange?()
    }

    var backgroundImageStatus: BackgroundImageStatus {
        let status = backgroundImages.imageStatus(
            mode: snapshot.backgroundMode,
            filename: snapshot.backgroundImageFilename
        )
        if status == .ready, currentBackgroundImage() == nil {
            return .unavailable
        }
        return status
    }

    /// Thumbnail for the expanded panel. Missing or broken files return nil so the panel can fall back.
    func currentBackgroundImage() -> NSImage? {
        guard snapshot.backgroundMode == .image,
              let url = backgroundImages.existingFile(filename: snapshot.backgroundImageFilename)
        else { return nil }
        return BackgroundImageCache.shared.image(at: url)
    }

    func chooseBackgroundImage() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowsOtherFileTypes = false
        panel.prompt = snapshot.backgroundImageFilename == nil ? "Choose" : "Replace"
        var types: [UTType] = [.png, .jpeg, .heic, .tiff]
        if let webp = UTType(filenameExtension: "webp") {
            types.append(webp)
        }
        panel.allowedContentTypes = types
        guard panel.runModal() == .OK, let url = panel.url else { return }
        installBackground(from: url)
    }

    func removeBackgroundImage() {
        let filename = snapshot.backgroundImageFilename
        if backgroundImages.existingFile(filename: filename) != nil {
            guard backgroundImages.removeManaged(filename: filename) else {
                backgroundMessage = "Could not remove the background image."
                return
            }
        }
        BackgroundImageCache.shared.invalidate()
        update {
            $0.backgroundMode = .systemMaterial
            $0.backgroundImageFilename = nil
        }
    }

    /// Live resize. The screen clamp is applied by the caller. Disk write waits until the drag ends.
    func applyLivePanelSize(width: CGFloat, height: CGFloat) {
        var next = snapshot
        next.panelSizeMode = .custom
        next.panelWidth = width
        next.panelHeight = height
        let clamped = next.clamped()
        guard clamped != snapshot else { return }
        snapshot = clamped
        onChange?()
    }

    func commitPanelSize() {
        store.save(snapshot)
    }

    func resetAppearanceAndBehavior() {
        _ = backgroundImages.removeManaged(filename: snapshot.backgroundImageFilename)
        BackgroundImageCache.shared.invalidate()
        store.resetAppearanceAndBehavior()
        snapshot = store.load()
        backgroundMessage = nil
        categoryNameDrafts = [:]
        onChange?()
    }

    private func installBackground(from url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        let previous = snapshot.backgroundImageFilename
        let filename: String
        do {
            filename = try backgroundImages.install(from: url)
        } catch {
            backgroundMessage = "Could not use that image. The previous background was kept."
            return
        }
        BackgroundImageCache.shared.invalidate()
        update {
            $0.backgroundMode = .image
            $0.backgroundImageFilename = filename
        }
        if let previous, previous != filename {
            _ = backgroundImages.removeManaged(filename: previous)
        }
    }

    func resolvedEdgeTabColor() -> RGBAColor {
        switch snapshot.edgeTabColorMode {
        case .custom:
            return snapshot.edgeTabCustomColor
        case .systemAccent:
            return Self.systemAccentColor(matching: windowAppearance)
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try LaunchAtLogin.setEnabled(enabled)
            launchAtLoginMessage = nil
        } catch {
            launchAtLoginMessage = error.localizedDescription
        }
        if launchAtLoginMessage == nil {
            launchAtLoginMessage = LaunchAtLogin.statusMessage
        }
        snapshot.launchAtLogin = LaunchAtLogin.isEnabled
        store.save(snapshot)
    }

    /// Mirrors the system Login Item. Does not register or unregister.
    func refreshLaunchAtLoginFromSystem() {
        launchAtLoginMessage = LaunchAtLogin.statusMessage
        let enabled = LaunchAtLogin.isEnabled
        guard snapshot.launchAtLogin != enabled else { return }
        snapshot.launchAtLogin = enabled
        store.save(snapshot)
    }

    func draftName(for category: PeekMeowCore.Category) -> String {
        categoryNameDrafts[category.id] ?? category.name
    }

    func setDraftName(_ name: String, for id: UUID) {
        categoryNameDrafts[id] = name
    }

    func commitRename(_ id: UUID) {
        guard let category = appState.categories.first(where: { $0.id == id }) else { return }
        let name = (categoryNameDrafts[id] ?? category.name)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name != category.name else {
            categoryNameDrafts[id] = category.name
            return
        }
        if appState.renameCategory(id: id, name: name) {
            categoryNameDrafts[id] = name
        } else {
            categoryNameDrafts[id] = category.name
        }
    }

    func recolorCategory(_ id: UUID, color: RGBAColor) {
        _ = appState.recolorCategory(id: id, color: color)
    }

    func archiveCategory(_ id: UUID) {
        categoryNameDrafts[id] = nil
        _ = appState.archiveCategory(id: id)
    }

    func moveCategory(_ id: UUID, by delta: Int) {
        _ = appState.moveCategory(id, by: delta)
    }

    private func observeSystemChanges() {
        let refresh: @Sendable (Notification) -> Void = { [weak self] _ in
            Task { @MainActor in
                self?.onChange?()
            }
        }
        systemObservers.append(
            NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
                object: nil,
                queue: nil,
                using: refresh
            )
        )
        for name in ["AppleInterfaceThemeChangedNotification", "AppleColorPreferencesChangedNotification"] {
            systemObservers.append(
                DistributedNotificationCenter.default().addObserver(
                    forName: Notification.Name(name),
                    object: nil,
                    queue: nil,
                    using: refresh
                )
            )
        }
    }

    private static func systemAccentColor(matching appearance: NSAppearance?) -> RGBAColor {
        let current = appearance ?? NSApp.effectiveAppearance
        var color = RGBAColor.accent
        current.performAsCurrentDrawingAppearance {
            guard let resolved = NSColor.controlAccentColor.usingColorSpace(.sRGB) else { return }
            color = RGBAColor(
                red: Double(resolved.redComponent),
                green: Double(resolved.greenComponent),
                blue: Double(resolved.blueComponent),
                alpha: 1
            )
        }
        return color
    }
}
