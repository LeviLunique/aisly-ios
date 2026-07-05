import Foundation

// MARK: - Snapshot storage

/// Actor box holding the last server state known to a remote repository so
/// `save*` calls can be turned into per-entity diffs.
actor RemoteSnapshotBox<Value: Sendable> {
    private var value: Value?

    func get() -> Value? {
        value
    }

    func set(_ newValue: Value?) {
        value = newValue
    }
}

// MARK: - Shared mapping helpers

enum RemoteMapping {
    /// Server sends colorHex as a JSON int; the domain stores UInt32. Values
    /// are 24-bit RGB, so clamping keeps out-of-range payloads safe.
    static func colorHex(fromServer value: Int) -> UInt32 {
        UInt32(truncatingIfNeeded: max(0, value))
    }

    static func colorHex(toServer value: UInt32) -> Int {
        Int(value)
    }

    static func unit(fromServer value: String?) -> ShoppingItem.Unit {
        value.flatMap(ShoppingItem.Unit.init(rawValue:)) ?? .unit
    }
}

// MARK: - Auth wire models

/// Body for `POST /api/users` (account creation). The server does not return a
/// token here, so registration is followed by a login call.
struct CreateUserWire: Encodable, Sendable {
    let email: String
    let password: String
    let name: String
}

/// Body for `POST /api/users/login`.
struct LoginWire: Encodable, Sendable {
    let email: String
    let password: String
}

/// User payload returned by the auth server (`UserResponse`).
struct UserWire: Decodable, Sendable {
    let id: Int
    let email: String
    let name: String
}

/// Response of `POST /api/users/login`.
struct LoginResponseWire: Decodable, Sendable {
    let token: String
    let user: UserWire
}

// MARK: - List / item wire models

struct RemoteListItemResponse: Decodable, Sendable {
    let id: UUID
    let name: String
    let quantity: Int
    let unit: String?
    let categoryName: String?
    let storeName: String?
    let plannedPrice: Decimal?
    let actualPrice: Decimal?
    let completed: Bool
    let note: String?
    let favorite: Bool?
    let sortOrder: Int?
    let createdAt: Date?
    let updatedAt: Date?
}

struct RemoteListResponse: Decodable, Sendable {
    let id: UUID
    let name: String
    let archived: Bool
    let budget: Decimal?
    let iconName: String?
    let colorHex: Int?
    let templateRecurrence: String?
    let sourceTemplateId: UUID?
    let pinned: Bool?
    let categories: [String]?
    let items: [RemoteListItemResponse]?
    let createdAt: Date?
    let updatedAt: Date?
}

struct RemoteItemRequest: Encodable, Sendable {
    var id: UUID?
    let name: String
    let quantity: Int
    let unit: String
    let categoryName: String
    let storeName: String?
    let plannedPrice: Decimal?
    let actualPrice: Decimal?
    let completed: Bool
    let note: String
    let favorite: Bool

    init(item: ShoppingItem, includeID: Bool) {
        self.id = includeID ? item.id : nil
        self.name = item.name
        self.quantity = item.quantity
        self.unit = item.unit.rawValue
        self.categoryName = item.category.rawValue
        self.storeName = item.storeName
        self.plannedPrice = item.plannedPrice
        self.actualPrice = item.actualPrice
        self.completed = item.isCompleted
        self.note = item.note
        self.favorite = item.isFavorite
    }
}

struct RemoteCreateListRequest: Encodable, Sendable {
    let id: UUID
    let name: String
    let budget: Decimal?
    let iconName: String
    let colorHex: Int
    let sourceTemplateId: UUID?
    let categories: [String]?
    let items: [RemoteItemRequest]
}

struct RemoteUpdateListRequest: Encodable, Sendable {
    let name: String
    let budget: Decimal?
    let iconName: String
    let colorHex: Int
    let categories: [String]?
}

struct RemoteCreateTemplateRequest: Encodable, Sendable {
    let id: UUID
    let name: String
    let recurrence: String
    let sourceListId: UUID?
    let budget: Decimal?
    let iconName: String
    let colorHex: Int
    let items: [RemoteItemRequest]
}

struct RemoteArchiveRequest: Encodable, Sendable {
    let archived: Bool
}

struct RemotePinRequest: Encodable, Sendable {
    let pinned: Bool
}

struct RemoteReorderRequest: Encodable, Sendable {
    let ids: [UUID]
}

struct RemoteCompletionRequest: Encodable, Sendable {
    let completed: Bool
}

// MARK: - Category wire models

struct RemoteCategoryResponse: Decodable, Sendable {
    let id: UUID
    let name: String
    let iconName: String?
    let colorHex: Int?
    let fixed: Bool?
    let sortOrder: Int?
}

struct RemoteCategoryRequest: Encodable, Sendable {
    let name: String
    let iconName: String
    let colorHex: Int
}

// MARK: - Catalog wire models

struct RemoteCatalogItemResponse: Decodable, Sendable {
    let id: UUID
    let name: String
    let categoryName: String?
    let storeName: String?
    let plannedPrice: Decimal?
    let actualPrice: Decimal?
    let archived: Bool?
    let favorite: Bool?
    let quantity: Int?
    let unit: String?
    let note: String?
    let createdAt: Date?
    let updatedAt: Date?
}

struct RemoteCatalogItemRequest: Encodable, Sendable {
    var id: UUID?
    let name: String
    let categoryName: String
    let storeName: String?
    let plannedPrice: Decimal?
    let actualPrice: Decimal?
    let archived: Bool
    let favorite: Bool
    let quantity: Int
    let unit: String
    let note: String

    init(entry: ShoppingItemCatalogEntry, includeID: Bool) {
        self.id = includeID ? entry.id : nil
        self.name = entry.name
        self.categoryName = entry.category.rawValue
        self.storeName = entry.storeName
        self.plannedPrice = entry.plannedPrice
        self.actualPrice = entry.actualPrice
        self.archived = entry.isArchived
        self.favorite = entry.isFavorite
        self.quantity = entry.quantity
        self.unit = entry.unit.rawValue
        self.note = entry.note
    }
}

// MARK: - History wire models

struct RemoteHistoryItemResponse: Decodable, Sendable {
    let id: UUID
    let name: String
    let quantity: Int
    let unit: String?
    let storeName: String?
    let plannedPrice: Decimal?
    let actualPrice: Decimal?
    let purchased: Bool
}

struct RemoteHistorySectionResponse: Decodable, Sendable {
    let id: String?
    let name: String
    let items: [RemoteHistoryItemResponse]
}

struct RemoteHistoryEntryResponse: Decodable, Sendable {
    let id: UUID
    let sourceListId: UUID?
    let sourceTemplateId: UUID?
    let name: String
    let finishedAt: Date
    let budget: Decimal?
    let plannedTotal: Decimal?
    let actualTotal: Decimal?
    let budgetDelta: Decimal?
    let planDelta: Decimal?
    let purchasedItemCount: Int?
    let totalItemCount: Int?
    let missingActualPriceCount: Int?
    let sections: [RemoteHistorySectionResponse]?
}

struct RemoteFinishListRequest: Encodable, Sendable {
    let id: UUID
    let finishedAt: Date
}
