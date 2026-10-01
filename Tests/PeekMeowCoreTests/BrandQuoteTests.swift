import Foundation
import PeekMeowCore

enum BrandQuoteTests {
    static func run() throws {
        try expectEqual(
            BrandQuote.text,
            "Toutes les grandes personnes ont d’abord été des enfants. Mais peu d’entre elles s’en souviennent."
        )
        try expect(BrandQuote.text.contains("\u{2019}"))
        try expectEqual(BrandQuote.isVisible(panelHeight: 349), false)
        try expectEqual(BrandQuote.isVisible(panelHeight: 350), true)
        try expectEqual(BrandQuote.isVisible(panelHeight: 460), true)
    }
}
