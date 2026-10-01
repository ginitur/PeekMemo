import CoreGraphics
import Foundation

/// One quiet line under Add Task. The wording is fixed and is not translated.
public enum BrandQuote: Sendable {
    public static let text = "Toutes les grandes personnes ont d’abord été des enfants. Mais peu d’entre elles s’en souviennent."

    /// Below this panel height the quote hides so tasks keep the space.
    public static let minimumPanelHeight: CGFloat = 350

    public static func isVisible(panelHeight: CGFloat) -> Bool {
        panelHeight >= minimumPanelHeight
    }
}
