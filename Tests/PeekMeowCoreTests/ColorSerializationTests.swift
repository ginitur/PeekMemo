import Foundation
import PeekMeowCore

enum ColorSerializationTests {
    static func run() throws {
        try roundTripRGBHex()
        try roundTripRGBAHex()
        try rejectsGarbage()
        try clampsOutOfRangeComponents()
        try jsonRoundTrip()
    }

    static func roundTripRGBHex() throws {
        let color = RGBAColor(red: 0.2, green: 0.48, blue: 0.96)
        guard let parsed = RGBAColor.parse(hex: color.hex) else {
            throw CheckError(message: "failed to parse \(color.hex)")
        }
        try expect(abs(parsed.red - color.red) < 0.01)
        try expect(abs(parsed.green - color.green) < 0.01)
        try expect(abs(parsed.blue - color.blue) < 0.01)
        try expectEqual(parsed.alpha, 1)
    }

    static func roundTripRGBAHex() throws {
        let color = RGBAColor(red: 1, green: 0, blue: 0, alpha: 0.5)
        guard let parsed = RGBAColor.parse(hex: color.hex) else {
            throw CheckError(message: "failed to parse \(color.hex)")
        }
        try expectEqual(parsed.red, 1)
        try expect(abs(parsed.alpha - 0.5) < 0.01)
    }

    static func rejectsGarbage() throws {
        try expect(RGBAColor.parse(hex: "not-a-color") == nil)
        try expect(RGBAColor.parse(hex: "#GG0000") == nil)
    }

    static func clampsOutOfRangeComponents() throws {
        let color = RGBAColor(red: 2, green: -1, blue: 0.5, alpha: 9)
        try expectEqual(color.red, 1)
        try expectEqual(color.green, 0)
        try expectEqual(color.alpha, 1)
    }

    static func jsonRoundTrip() throws {
        let color = RGBAColor.ideas
        let data = try JSONEncoder().encode(color)
        let decoded = try JSONDecoder().decode(RGBAColor.self, from: data)
        try expectEqual(decoded, color)
    }
}
