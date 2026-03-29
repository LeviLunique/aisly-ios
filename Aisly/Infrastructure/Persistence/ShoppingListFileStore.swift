import Foundation

actor ShoppingListFileStore {
    private let fileURL: URL
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(fileURL: URL) {
        self.fileURL = fileURL

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder
    }

    func load() throws -> [StoredShoppingList] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)

        guard !data.isEmpty else {
            return []
        }

        return try decoder.decode([StoredShoppingList].self, from: data)
    }

    func save(_ lists: [StoredShoppingList]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let data = try encoder.encode(lists)
        try data.write(to: fileURL, options: .atomic)
    }
}

struct StoredShoppingList: Codable, Equatable {
    let id: UUID
    let name: String
    let createdAt: Date
    let updatedAt: Date
    let isArchived: Bool
    let items: [StoredShoppingItem]
    let templateConfiguration: ShoppingList.TemplateConfiguration?

    init(
        id: UUID,
        name: String,
        createdAt: Date,
        updatedAt: Date,
        isArchived: Bool,
        items: [StoredShoppingItem],
        templateConfiguration: ShoppingList.TemplateConfiguration?
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
        self.items = items
        self.templateConfiguration = templateConfiguration
    }

    init(list: ShoppingList) {
        id = list.id
        name = list.name
        createdAt = list.createdAt
        updatedAt = list.updatedAt
        isArchived = list.isArchived
        items = list.items.map(StoredShoppingItem.init(item:))
        templateConfiguration = list.templateConfiguration
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        isArchived = try container.decode(Bool.self, forKey: .isArchived)
        items = try container.decodeIfPresent([StoredShoppingItem].self, forKey: .items) ?? []
        templateConfiguration = try container.decodeIfPresent(ShoppingList.TemplateConfiguration.self, forKey: .templateConfiguration)
    }

    var model: ShoppingList {
        ShoppingList(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isArchived: isArchived,
            items: items.map(\.model),
            templateConfiguration: templateConfiguration
        )
    }
}

struct StoredShoppingItem: Codable, Equatable {
    let id: UUID
    let name: String
    let quantity: Int
    let category: ShoppingItem.Category
    let plannedPrice: Decimal?
    let actualPrice: Decimal?
    let createdAt: Date
    let updatedAt: Date
    let sortOrder: Int

    init(item: ShoppingItem) {
        id = item.id
        name = item.name
        quantity = item.quantity
        category = item.category
        plannedPrice = item.plannedPrice
        actualPrice = item.actualPrice
        createdAt = item.createdAt
        updatedAt = item.updatedAt
        sortOrder = item.sortOrder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        quantity = try container.decode(Int.self, forKey: .quantity)
        category = try container.decode(ShoppingItem.Category.self, forKey: .category)
        plannedPrice = try container.decodeIfPresent(Decimal.self, forKey: .plannedPrice)
        actualPrice = try container.decodeIfPresent(Decimal.self, forKey: .actualPrice)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        sortOrder = try container.decode(Int.self, forKey: .sortOrder)
    }

    var model: ShoppingItem {
        ShoppingItem(
            id: id,
            name: name,
            quantity: quantity,
            category: category,
            plannedPrice: plannedPrice,
            actualPrice: actualPrice,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sortOrder: sortOrder
        )
    }
}
