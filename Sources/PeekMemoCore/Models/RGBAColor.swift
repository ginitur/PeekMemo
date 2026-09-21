import Foundation

/// Persistable sRGB color. Never store a SwiftUI `Color` directly.
public struct RGBAColor: Equatable, Sendable, Codable, Hashable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = Self.clamp01(red)
        self.green = Self.clamp01(green)
        self.blue = Self.clamp01(blue)
        self.alpha = Self.clamp01(alpha)
    }

    public static let accent = RGBAColor(red: 0.20, green: 0.48, blue: 0.96)
    public static let today = RGBAColor(red: 0.20, green: 0.48, blue: 0.96)
    public static let inbox = RGBAColor(red: 0.55, green: 0.55, blue: 0.58)
    public static let ideas = RGBAColor(red: 0.69, green: 0.42, blue: 0.86)

    public var hex: String {
        let r = Int((red * 255).rounded())
        let g = Int((green * 255).rounded())
        let b = Int((blue * 255).rounded())
        let a = Int((alpha * 255).rounded())
        if a == 255 {
            return String(format: "#%02X%02X%02X", r, g, b)
        }
        return String(format: "#%02X%02X%02X%02X", r, g, b, a)
    }

    public static func parse(hex: String) -> RGBAColor? {
        var raw = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.hasPrefix("#") {
            raw.removeFirst()
        }
        guard raw.count == 6 || raw.count == 8, let value = UInt32(raw, radix: 16) else {
            return nil
        }
        if raw.count == 6 {
            return RGBAColor(
                red: Double((value >> 16) & 0xFF) / 255,
                green: Double((value >> 8) & 0xFF) / 255,
                blue: Double(value & 0xFF) / 255,
                alpha: 1
            )
        }
        return RGBAColor(
            red: Double((value >> 24) & 0xFF) / 255,
            green: Double((value >> 16) & 0xFF) / 255,
            blue: Double((value >> 8) & 0xFF) / 255,
            alpha: Double(value & 0xFF) / 255
        )
    }

    private static func clamp01(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
