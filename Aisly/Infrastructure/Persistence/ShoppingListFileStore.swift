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

actor ShoppingItemCatalogFileStore {
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

    func load() throws -> [ShoppingItemCatalogEntry] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)

        guard !data.isEmpty else {
            return []
        }

        return try decoder.decode([StoredShoppingItemCatalogEntry].self, from: data).map(\.model)
    }

    func save(_ entries: [ShoppingItemCatalogEntry]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let data = try encoder.encode(entries.map(StoredShoppingItemCatalogEntry.init(entry:)))
        try data.write(to: fileURL, options: .atomic)
    }
}

actor PurchaseHistoryFileStore {
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

    func load() throws -> [PurchaseHistoryEntry] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)

        guard !data.isEmpty else {
            return []
        }

        return try decoder.decode([PurchaseHistoryEntry].self, from: data)
    }

    func save(_ entries: [PurchaseHistoryEntry]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let data = try encoder.encode(entries)
        try data.write(to: fileURL, options: .atomic)
    }
}

actor ShoppingCategoryFileStore {
    private let fileURL: URL
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(fileURL: URL) {
        self.fileURL = fileURL

        let decoder = JSONDecoder()
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder
    }

    func load() throws -> [ShoppingCategoryDefinition] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return ShoppingCategoryDefinition.defaultDefinitions
        }

        let data = try Data(contentsOf: fileURL)

        guard !data.isEmpty else {
            return ShoppingCategoryDefinition.defaultDefinitions
        }

        let definitions = try decoder.decode([ShoppingCategoryDefinition].self, from: data)
        return definitions.isEmpty
            ? ShoppingCategoryDefinition.defaultDefinitions
            : ShoppingCategoryDefinition.normalizedDefinitions(definitions)
    }

    func save(_ definitions: [ShoppingCategoryDefinition]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let data = try encoder.encode(ShoppingCategoryDefinition.normalizedDefinitions(definitions))
        try data.write(to: fileURL, options: .atomic)
    }
}

struct StoredShoppingList: Codable, Equatable {
    let id: UUID
    let name: String
    let createdAt: Date
    let updatedAt: Date
    let isArchived: Bool
    let budget: Decimal?
    let iconName: String
    let colorHex: UInt32
    let categories: [ShoppingItem.Category]
    let items: [StoredShoppingItem]
    let templateConfiguration: ShoppingList.TemplateConfiguration?
    let sourceTemplateID: UUID?
    let isPinned: Bool

    init(
        id: UUID,
        name: String,
        createdAt: Date,
        updatedAt: Date,
        isArchived: Bool,
        budget: Decimal?,
        iconName: String,
        colorHex: UInt32,
        categories: [ShoppingItem.Category],
        items: [StoredShoppingItem],
        templateConfiguration: ShoppingList.TemplateConfiguration?,
        sourceTemplateID: UUID?,
        isPinned: Bool = false
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
        self.budget = budget
        self.iconName = iconName
        self.colorHex = colorHex
        self.categories = categories
        self.items = items
        self.templateConfiguration = templateConfiguration
        self.sourceTemplateID = sourceTemplateID
        self.isPinned = isPinned
    }

    init(list: ShoppingList) {
        id = list.id
        name = list.name
        createdAt = list.createdAt
        updatedAt = list.updatedAt
        isArchived = list.isArchived
        budget = list.budget
        iconName = list.iconName
        colorHex = list.colorHex
        categories = list.categories
        items = list.items.map(StoredShoppingItem.init(item:))
        templateConfiguration = list.templateConfiguration
        sourceTemplateID = list.sourceTemplateID
        isPinned = list.isPinned
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        isArchived = try container.decode(Bool.self, forKey: .isArchived)
        budget = try container.decodeIfPresent(Decimal.self, forKey: .budget)
        iconName = try container.decodeIfPresent(String.self, forKey: .iconName)
            ?? ShoppingList.defaultIconName
        colorHex = try container.decodeIfPresent(UInt32.self, forKey: .colorHex)
            ?? ShoppingList.defaultColorHex
        categories = try container.decodeIfPresent([ShoppingItem.Category].self, forKey: .categories)
            ?? ShoppingItem.Category.defaultCategories
        items = try container.decodeIfPresent([StoredShoppingItem].self, forKey: .items) ?? []
        templateConfiguration = try container.decodeIfPresent(ShoppingList.TemplateConfiguration.self, forKey: .templateConfiguration)
        sourceTemplateID = try container.decodeIfPresent(UUID.self, forKey: .sourceTemplateID)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
    }

    var model: ShoppingList {
        ShoppingList(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isArchived: isArchived,
            budget: budget,
            iconName: iconName,
            colorHex: colorHex,
            categories: ShoppingList.normalizedCategories(categories + items.map(\.category)),
            items: items.map(\.model),
            templateConfiguration: templateConfiguration,
            sourceTemplateID: sourceTemplateID,
            isPinned: isPinned
        )
    }
}

struct StoredShoppingItemCatalogEntry: Codable, Equatable {
    let id: UUID
    let name: String
    let category: ShoppingItem.Category
    let storeName: String?
    let plannedPrice: Decimal?
    let actualPrice: Decimal?
    let isArchived: Bool
    let createdAt: Date
    let updatedAt: Date
    let isFavorite: Bool
    let quantity: Int
    let unit: ShoppingItem.Unit
    let note: String

    init(entry: ShoppingItemCatalogEntry) {
        id = entry.id
        name = entry.name
        category = entry.category
        storeName = entry.storeName
        plannedPrice = entry.plannedPrice
        actualPrice = entry.actualPrice
        isArchived = entry.isArchived
        createdAt = entry.createdAt
        updatedAt = entry.updatedAt
        isFavorite = entry.isFavorite
        quantity = entry.quantity
        unit = entry.unit
        note = entry.note
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decode(ShoppingItem.Category.self, forKey: .category)
        storeName = try container.decodeIfPresent(String.self, forKey: .storeName)
        plannedPrice = try container.decodeIfPresent(Decimal.self, forKey: .plannedPrice)
        actualPrice = try container.decodeIfPresent(Decimal.self, forKey: .actualPrice)
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        quantity = try container.decodeIfPresent(Int.self, forKey: .quantity) ?? 1
        unit = try container.decodeIfPresent(ShoppingItem.Unit.self, forKey: .unit) ?? .unit
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
    }

    var model: ShoppingItemCatalogEntry {
        ShoppingItemCatalogEntry(
            id: id,
            name: name,
            category: category,
            storeName: storeName,
            plannedPrice: plannedPrice,
            actualPrice: actualPrice,
            isArchived: isArchived,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isFavorite: isFavorite,
            quantity: quantity,
            unit: unit,
            note: note
        )
    }
}

struct StoredShoppingItem: Codable, Equatable {
    let id: UUID
    let name: String
    let quantity: Int
    let category: ShoppingItem.Category
    let storeName: String?
    let plannedPrice: Decimal?
    let actualPrice: Decimal?
    let isCompleted: Bool
    let createdAt: Date
    let updatedAt: Date
    let sortOrder: Int
    let unit: ShoppingItem.Unit
    let note: String
    let isFavorite: Bool

    init(item: ShoppingItem) {
        id = item.id
        name = item.name
        quantity = item.quantity
        category = item.category
        storeName = item.storeName
        plannedPrice = item.plannedPrice
        actualPrice = item.actualPrice
        isCompleted = item.isCompleted
        createdAt = item.createdAt
        updatedAt = item.updatedAt
        sortOrder = item.sortOrder
        unit = item.unit
        note = item.note
        isFavorite = item.isFavorite
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        quantity = try container.decode(Int.self, forKey: .quantity)
        category = try container.decode(ShoppingItem.Category.self, forKey: .category)
        storeName = try container.decodeIfPresent(String.self, forKey: .storeName)
        plannedPrice = try container.decodeIfPresent(Decimal.self, forKey: .plannedPrice)
        actualPrice = try container.decodeIfPresent(Decimal.self, forKey: .actualPrice)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        unit = try container.decodeIfPresent(ShoppingItem.Unit.self, forKey: .unit) ?? .unit
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
    }

    var model: ShoppingItem {
        ShoppingItem(
            id: id,
            name: name,
            quantity: quantity,
            category: category,
            storeName: storeName,
            plannedPrice: plannedPrice,
            actualPrice: actualPrice,
            isCompleted: isCompleted,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sortOrder: sortOrder,
            unit: unit,
            note: note,
            isFavorite: isFavorite
        )
    }
}
