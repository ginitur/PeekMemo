import CoreGraphics
import Foundation
import PeekMemoCore

enum AtmosphereMarkTests {
    static func run() throws {
        let normal = AtmosphereMark.layout(panelWidth: 340, panelHeight: 460, lightBackground: false)
        let fraction = normal.width / 340
        try expect(fraction >= AtmosphereMark.minimumWidthFraction && fraction <= AtmosphereMark.maximumWidthFraction)
        try expectEqual(normal.opacity, AtmosphereMark.darkOpacity)
        try expect(normal.bleed > 0 && normal.bleed < normal.width)

        let wide = AtmosphereMark.layout(panelWidth: 480, panelHeight: 640, lightBackground: false)
        try expectEqual(wide.width / 480, AtmosphereMark.maximumWidthFraction)
        try expect(wide.width > normal.width)

        let light = AtmosphereMark.layout(panelWidth: 340, panelHeight: 460, lightBackground: true)
        try expectEqual(light.width, normal.width)
        try expectEqual(light.opacity, AtmosphereMark.lightOpacity)
        try expect(light.opacity < normal.opacity)

        let narrow = AtmosphereMark.layout(panelWidth: 240, panelHeight: 460, lightBackground: false)
        try expect(narrow.width / 240 < AtmosphereMark.minimumWidthFraction)

        let short = AtmosphereMark.layout(panelWidth: 340, panelHeight: 300, lightBackground: false)
        try expect(short.width < normal.width)
        try expect(short.opacity < normal.opacity)

        let cramped = AtmosphereMark.layout(panelWidth: 180, panelHeight: 200, lightBackground: true)
        try expect(cramped.opacity < 0.05)
        try expect(cramped.width < 40)

        let hidden = AtmosphereMark.layout(panelWidth: 0, panelHeight: 460, lightBackground: false)
        try expectEqual(hidden.width, 0)
        try expectEqual(hidden.opacity, 0)
    }
}
