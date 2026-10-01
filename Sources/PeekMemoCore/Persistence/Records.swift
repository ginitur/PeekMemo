import Foundation
import GRDB

struct CategoryRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "categories"

    var id: String
    var name: String
    var icon: String?
    var color: String?
    var sortOrder: Int
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case icon
        case color
        case sortOrder = "sort_order"
        case isArchived = "is_archived"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(_ category: Category) {
        id = category.id.uuidString
        name = category.name
        icon = category.icon
        color = category.color.hex
        sortOrder = category.sortOrder
        isArchived = category.isArchived
        createdAt = category.createdAt
        updatedAt = category.updatedAt
    }

    func model() throws -> Category {
        guard let uuid = UUID(uuidString: id) else {
            throw PersistenceError.corruptIdentifier(id)
        }
        return Category(
            id: uuid,
            name: name,
            icon: icon ?? "folder",
            color: color.flatMap(RGBAColor.parse(hex:)) ?? .accent,
            sortOrder: sortOrder,
            isArchived: isArchived,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct MemoItemRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "memo_items"

    var id: String
    var categoryId: String?
    var parentId: String?
    var type: String
    var title: String
    var body: String?
    var isCompleted: Bool
    var completedAt: Date?
    var sortOrder: Int
    var scheduledDate: Date?
    var dueDate: Date?
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case categoryId = "category_id"
        case parentId = "parent_id"
        case type
        case title
        case body
        case isCompleted = "is_completed"
        case completedAt = "completed_at"
        case sortOrder = "sort_order"
        case scheduledDate = "scheduled_date"
        case dueDate = "due_date"
        case isArchived = "is_archived"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(_ item: MemoItem) {
        id = item.id.uuidString
        categoryId = item.categoryId?.uuidString
        parentId = item.parentId?.uuidString
        type = item.type.rawValue
        title = item.title
        body = item.body
        isCompleted = item.isCompleted
        completedAt = item.completedAt
        sortOrder = item.sortOrder
        scheduledDate = item.scheduledDate
        dueDate = item.dueDate
        isArchived = item.isArchived
        createdAt = item.createdAt
        updatedAt = item.updatedAt
    }

    func model() throws -> MemoItem {
        guard let uuid = UUID(uuidString: id) else {
            throw PersistenceError.corruptIdentifier(id)
        }
        let kind = ItemType(rawValue: type) ?? .task
        return MemoItem(
            id: uuid,
            categoryId: categoryId.flatMap(UUID.init(uuidString:)),
            parentId: parentId.flatMap(UUID.init(uuidString:)),
            type: kind,
            title: title,
            body: body ?? "",
            isCompleted: isCompleted,
            completedAt: completedAt,
            sortOrder: sortOrder,
            dueDate: dueDate,
            scheduledDate: scheduledDate,
            forToday: false,
            isArchived: isArchived,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
