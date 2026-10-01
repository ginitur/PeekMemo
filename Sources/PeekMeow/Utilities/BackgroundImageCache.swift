import AppKit
import ImageIO
import PeekMeowCore

/// One decoded thumbnail for the current background. Hover must not decode the file again.
@MainActor
final class BackgroundImageCache {
    static let shared = BackgroundImageCache()

    /// Longest side of the display bitmap. A 6000 px photo is not decoded in full.
    static let maxPixelSize = 1600

    private var cached: (key: String, image: NSImage)?

    func image(at url: URL) -> NSImage? {
        guard let key = cacheKey(for: url) else { return nil }
        if cached?.key == key {
            return cached?.image
        }
        guard let image = Self.thumbnail(at: url, maxPixel: Self.maxPixelSize) else {
            return nil
        }
        cached = (key, image)
        return image
    }

    func invalidate() {
        cached = nil
    }

    private func cacheKey(for url: URL) -> String? {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
        guard let size = values?.fileSize, size > 0 else { return nil }
        let modified = values?.contentModificationDate?.timeIntervalSince1970 ?? 0
        return "\(url.path)|\(size)|\(modified)"
    }

    private static func thumbnail(at url: URL, maxPixel: Int) -> NSImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else { return nil }
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
        ] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
}
