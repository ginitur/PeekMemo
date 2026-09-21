import Foundation

public enum MemoType: String, Codable, Sendable, Equatable {
    case note
    case checklist
}

public struct Memo: Identifiable, Equatable, Sendable, Codable {
    public var id: UUID
    public var groupId: UUID
    public var text: String
    public var type: MemoType
    public var isCompleted: Bool
    public var isArchived: Bool
    public var sortOrder: Int
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        groupId: UUID,
        text: String,
        type: MemoType = .note,
        isCompleted: Bool = false,
        isArchived: Bool = false,
        sortOrder: Int,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.groupId = groupId
        self.text = text
        self.type = type
        self.isCompleted = isCompleted
        self.isArchived = isArchived
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct MemoGroup: Identifiable, Equatable, Sendable, Codable {
    public var id: UUID
    public var title: String
    public var icon: String
    public var color: RGBAColor
    public var sortOrder: Int
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        icon: String,
        color: RGBAColor,
        sortOrder: Int,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.color = color
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
