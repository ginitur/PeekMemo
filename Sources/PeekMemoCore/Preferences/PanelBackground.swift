import Foundation

public enum PanelBackgroundMode: String, Codable, Sendable, CaseIterable {
    case systemMaterial
    case solidColor
    case image
}

/// Fill crops to the panel. Fit shows the whole image. Neither stretches.
public enum BackgroundImageContentMode: String, Codable, Sendable, CaseIterable {
    case fill
    case fit
}

public enum BackgroundImagePosition: String, Codable, Sendable, CaseIterable {
    case top
    case center
    case bottom
}

public enum BackgroundImageKind: String, Sendable, Equatable {
    case png
    case jpeg
    case heic
    case tiff
    case webp

    public var storedExtension: String {
        switch self {
        case .png: "png"
        case .jpeg: "jpg"
        case .heic: "heic"
        case .tiff: "tiff"
        case .webp: "webp"
        }
    }
}

public enum BackgroundImageError: Error, Equatable, Sendable {
    case unreadable
    case unsupported
    case copyFailed
    case rejectedName
}

public enum BackgroundImageStatus: Equatable, Sendable {
    case notApplicable
    case empty
    case ready
    case unavailable
}

/// Light or dark text when a solid fill would hide the theme color.
public enum PanelContentScheme: Equatable, Sendable {
    case light
    case dark
}

public enum BackgroundImageValidator {
    public static let allowedExtensions: Set<String> = [
        "png", "jpg", "jpeg", "heic", "tif", "tiff", "webp",
    ]

    public static func kind(at url: URL) -> BackgroundImageKind? {
        let ext = url.pathExtension.lowercased()
        guard allowedExtensions.contains(ext) else { return nil }
        guard let header = headerBytes(at: url) else { return nil }
        guard let detected = kind(header: header) else { return nil }
        switch (ext, detected) {
        case ("png", .png),
             ("jpg", .jpeg), ("jpeg", .jpeg),
             ("heic", .heic),
             ("tif", .tiff), ("tiff", .tiff),
             ("webp", .webp):
            return detected
        default:
            return nil
        }
    }

    public static func kind(header: Data) -> BackgroundImageKind? {
        if header.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return .png }
        if header.starts(with: [0xFF, 0xD8, 0xFF]) { return .jpeg }
        if header.starts(with: [0x49, 0x49, 0x2A, 0x00]) || header.starts(with: [0x4D, 0x4D, 0x00, 0x2A]) {
            return .tiff
        }
        if header.count >= 12,
           header[0..<4].elementsEqual("RIFF".utf8),
           header[8..<12].elementsEqual("WEBP".utf8) {
            return .webp
        }
        if header.count >= 12, header[4..<8].elementsEqual("ftyp".utf8) {
            let brand = String(decoding: header[8..<12], as: UTF8.self)
            let brands = ["heic", "heix", "hevc", "hevx", "mif1", "msf1"]
            if brands.contains(brand) { return .heic }
        }
        return nil
    }

    private static func headerBytes(at url: URL) -> Data? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        return try? handle.read(upToCount: 32)
    }
}

/// Copies a chosen picture into PeekMemo's own folder. Never deletes the source file.
public struct BackgroundImageStore: Sendable {
    public let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    /// `~/Library/Application Support/PeekMemo/Backgrounds`
    public static func applicationSupportDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
                .appendingPathComponent("Library/Application Support", isDirectory: true)
        return base
            .appendingPathComponent("PeekMemo", isDirectory: true)
            .appendingPathComponent("Backgrounds", isDirectory: true)
    }

    public static func isSafeFilename(_ name: String) -> Bool {
        guard name.hasPrefix("background-"), name.count < 120 else { return false }
        guard !name.contains("/"), !name.contains("\\"), !name.contains("..") else { return false }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-.")
        return name.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    /// Copies `source` to a new UUID file. The previous managed file is left in place
    /// so a failed copy cannot drop the current background. The caller deletes it after saving.
    public func install(from source: URL) throws -> String {
        guard FileManager.default.isReadableFile(atPath: source.path) else {
            throw BackgroundImageError.unreadable
        }
        guard let kind = BackgroundImageValidator.kind(at: source) else {
            throw BackgroundImageError.unsupported
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let filename = "background-\(UUID().uuidString).\(kind.storedExtension)"
        guard Self.isSafeFilename(filename) else { throw BackgroundImageError.rejectedName }
        let destination = directory.appendingPathComponent(filename)
        guard isInsideStore(destination) else { throw BackgroundImageError.rejectedName }
        guard source.standardizedFileURL != destination.standardizedFileURL else {
            throw BackgroundImageError.copyFailed
        }
        do {
            try FileManager.default.copyItem(at: source, to: destination)
        } catch {
            throw BackgroundImageError.copyFailed
        }
        guard existingFile(filename: filename) != nil else {
            try? FileManager.default.removeItem(at: destination)
            throw BackgroundImageError.copyFailed
        }
        return filename
    }

    /// Deletes one managed copy. Returns false for names that are not inside this folder.
    /// A missing file is success: there is nothing left to remove.
    @discardableResult
    public func removeManaged(filename: String?) -> Bool {
        guard let filename, Self.isSafeFilename(filename) else { return false }
        guard let url = managedURL(filename) else { return false }
        guard FileManager.default.fileExists(atPath: url.path) else { return true }
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            return false
        }
    }

    public func existingFile(filename: String?) -> URL? {
        guard let filename, Self.isSafeFilename(filename), let url = managedURL(filename) else { return nil }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
            return nil
        }
        return url
    }

    public func imageStatus(mode: PanelBackgroundMode, filename: String?) -> BackgroundImageStatus {
        guard mode == .image else { return .notApplicable }
        guard let filename, Self.isSafeFilename(filename) else { return .empty }
        return existingFile(filename: filename) == nil ? .unavailable : .ready
    }

    private func managedURL(_ filename: String) -> URL? {
        let url = directory.appendingPathComponent(filename, isDirectory: false)
        guard isInsideStore(url) else { return nil }
        return url
    }

    private func isInsideStore(_ url: URL) -> Bool {
        let root = directory.standardizedFileURL.path
        let target = url.standardizedFileURL.path
        let prefix = root.hasSuffix("/") ? root : root + "/"
        return target.hasPrefix(prefix)
    }
}

public enum BackgroundPresentation {
    public static let solidContrastOpacity = 0.55
    public static let lightLuminance = 0.62
    public static let darkLuminance = 0.28

    public static func relativeLuminance(_ color: RGBAColor) -> Double {
        func channel(_ value: Double) -> Double {
            if value <= 0.04045 { return value / 12.92 }
            return pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(color.red) + 0.7152 * channel(color.green) + 0.0722 * channel(color.blue)
    }

    /// Nil keeps the theme. An opaque light fill asks for dark text, and the reverse.
    public static func contentColorScheme(
        mode: PanelBackgroundMode,
        solid: RGBAColor,
        solidOpacity: Double
    ) -> PanelContentScheme? {
        guard mode == .solidColor, solidOpacity >= solidContrastOpacity else { return nil }
        let luminance = relativeLuminance(solid)
        if luminance >= lightLuminance { return .light }
        if luminance <= darkLuminance { return .dark }
        return nil
    }
}
