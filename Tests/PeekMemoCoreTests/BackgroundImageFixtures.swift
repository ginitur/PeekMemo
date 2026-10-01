import Foundation

enum BackgroundImageFixtures {
    static let png = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==")!

    static let jpeg = Data([0xFF, 0xD8, 0xFF, 0xD9])

    static var heic: Data {
        var data = Data([0x00, 0x00, 0x00, 0x18])
        data.append(contentsOf: "ftypheic".utf8)
        data.append(contentsOf: [0, 0, 0, 0])
        data.append(contentsOf: "heic".utf8)
        return data
    }

    static var tiff: Data {
        Data([0x49, 0x49, 0x2A, 0x00, 0x08, 0x00, 0x00, 0x00])
    }

    static var webp: Data {
        var data = Data("RIFF".utf8)
        data.append(contentsOf: [0x18, 0x00, 0x00, 0x00])
        data.append(contentsOf: "WEBP".utf8)
        data.append(contentsOf: [0, 0, 0, 0])
        return data
    }

    static func write(_ data: Data, named name: String, in directory: URL) throws -> URL {
        let url = directory.appendingPathComponent(name)
        try data.write(to: url)
        return url
    }
}
