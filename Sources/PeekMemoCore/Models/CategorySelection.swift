import Foundation

/// Category menu choice. Selecting a category never pins the panel.
public struct CategorySelectionState: Equatable, Sendable {
    public var selectedCategoryID: UUID?
    public private(set) var pinned: Bool

    public init(selectedCategoryID: UUID? = nil, pinned: Bool = false) {
        self.selectedCategoryID = selectedCategoryID
        self.pinned = pinned
    }

    public var showsAll: Bool { selectedCategoryID == nil }

    public mutating func selectAll() {
        selectedCategoryID = nil
    }

    public mutating func selectCategory(_ id: UUID) {
        selectedCategoryID = id
    }

    /// Menu choices update the filter only. `pinned` stays unchanged.
    public mutating func applyMenuChoice(_ id: UUID?) {
        selectedCategoryID = id
    }
}
