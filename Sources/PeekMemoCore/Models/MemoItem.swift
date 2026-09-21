import Foundation

public enum ItemType: String, Codable, Sendable, Equatable {
    case note
    case task
}

public struct MemoItem: Identifiable, Equatable, Sendable, Codable {
    public var id: UUID
    public var categoryId: UUID?
    public var parentId: UUID?
    public var type: ItemType
    public var title: String
    public var body: String
    public var isCompleted: Bool
    public var completedAt: Date?
    public var sortOrder: Int
    public var dueDate: Date?
    public var scheduledDate: Date?
    public var forToday: Bool
    public var isArchived: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        categoryId: UUID? = nil,
        parentId: UUID? = nil,
        type: ItemType = .task,
        title: String,
        body: String = "",
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        sortOrder: Int,
        dueDate: Date? = nil,
        scheduledDate: Date? = nil,
        forToday: Bool = false,
        isArchived: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.categoryId = categoryId
        self.parentId = parentId
        self.type = type
        self.title = title
        self.body = body
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.sortOrder = sortOrder
        self.dueDate = dueDate
        self.scheduledDate = scheduledDate
        self.forToday = forToday
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var isRoot: Bool { parentId == nil }
}

public struct Category: Identifiable, Equatable, Sendable, Codable {
    public var id: UUID
    public var name: String
    public var icon: String
    public var color: RGBAColor
    public var sortOrder: Int
    public var isArchived: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        color: RGBAColor,
        sortOrder: Int,
        isArchived: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.sortOrder = sortOrder
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum CategoryFilter: Equatable, Sendable, Hashable {
    case all
    case category(UUID)
}
