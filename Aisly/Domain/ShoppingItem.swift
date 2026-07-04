import Foundation

struct ShoppingItem: Identifiable, Equatable, Sendable {
    struct Category: CaseIterable, Codable, Hashable, Identifiable, Sendable {
        static let produce = Category("produce")
        static let dairy = Category("dairy")
        static let protein = Category("protein")
        static let pantry = Category("pantry")
        static let household = Category("household")
        static let frozen = Category("frozen")
        static let other = Category("other")

        static let defaultCategories: [Category] = [
            .produce,
            .dairy,
            .protein,
            .pantry,
            .household,
            .frozen,
            .other
        ]

        static var allCases: [Category] {
            defaultCategories
        }

        let rawValue: String

        var id: String {
            normalizedIdentifier
        }

        var normalizedIdentifier: String {
            Self.normalizedIdentifier(for: rawValue)
        }

        var isDefault: Bool {
            Self.defaultCategories.contains { $0.matches(self) }
        }

        init(_ rawValue: String) {
            let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            self.rawValue = trimmedValue.isEmpty ? Self.other.rawValue : trimmedValue
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            self.init(try container.decode(String.self))
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }

        func matches(_ category: Category) -> Bool {
            normalizedIdentifier == category.normalizedIdentifier
        }

        static func == (lhs: Category, rhs: Category) -> Bool {
            lhs.matches(rhs)
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(normalizedIdentifier)
        }

        static func normalizedIdentifier(for value: String) -> String {
            value
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
                .lowercased()
        }
    }

    enum SortOption: String, CaseIterable, Identifiable, Sendable {
        case category
        case name
        case plannedPrice
        case actualPrice

        var id: String { rawValue }
    }

    enum Unit: String, CaseIterable, Codable, Identifiable, Sendable {
        case unit = "un"
        case gram = "g"
        case kilogram = "kg"
        case milliliter = "mL"
        case liter = "L"
        var id: String { rawValue }
    }

    let id: UUID
    var name: String
    var quantity: Int
    var category: Category
    var storeName: String?
    var plannedPrice: Decimal?
    var actualPrice: Decimal?
    var isCompleted: Bool
    let createdAt: Date
    var updatedAt: Date
    var sortOrder: Int
    var unit: Unit = .unit
    var note: String = ""
    var isFavorite: Bool = false

    var plannedTotal: Decimal? {
        plannedPrice.map { $0 * Decimal(quantity) }
    }

    var actualTotal: Decimal? {
        actualPrice.map { $0 * Decimal(quantity) }
    }

    static func make(
        id: UUID,
        name: String,
        quantity: Int,
        unit: Unit = .unit,
        note: String = "",
        isFavorite: Bool = false,
        category: Category,
        storeName: String?,
        plannedPrice: Decimal?,
        actualPrice: Decimal?,
        isCompleted: Bool = false,
        sortOrder: Int,
        now: Date
    ) -> ShoppingItem {
        ShoppingItem(
            id: id,
            name: name,
            quantity: quantity,
            category: category,
            storeName: storeName,
            plannedPrice: plannedPrice,
            actualPrice: actualPrice,
            isCompleted: isCompleted,
            createdAt: now,
            updatedAt: now,
            sortOrder: sortOrder,
            unit: unit,
            note: note,
            isFavorite: isFavorite
        )
    }

    func updating(
        name: String,
        quantity: Int,
        unit: Unit,
        note: String,
        isFavorite: Bool,
        category: Category,
        storeName: String?,
        plannedPrice: Decimal?,
        actualPrice: Decimal?,
        isCompleted: Bool,
        updatedAt: Date
    ) -> ShoppingItem {
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

    func reordered(sortOrder: Int, updatedAt: Date) -> ShoppingItem {
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

    func updatingCompletion(
        isCompleted: Bool,
        updatedAt: Date
    ) -> ShoppingItem {
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

    func updatingActualPrice(
        _ actualPrice: Decimal?,
        updatedAt: Date
    ) -> ShoppingItem {
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

    func copiedForTemplateReuse(
        id: UUID,
        updatedAt: Date,
        sortOrder: Int
    ) -> ShoppingItem {
        ShoppingItem(
            id: id,
            name: name,
            quantity: quantity,
            category: category,
            storeName: storeName,
            plannedPrice: plannedPrice,
            actualPrice: nil,
            isCompleted: false,
            createdAt: updatedAt,
            updatedAt: updatedAt,
            sortOrder: sortOrder,
            unit: unit,
            note: note,
            isFavorite: isFavorite
        )
    }
}

enum ItemsSortOption: String, CaseIterable, Identifiable, Sendable {
    case nameAscending
    case nameDescending
    case createdAtDescending
    case createdAtAscending
    case plannedPriceHighest
    case plannedPriceLowest
    case actualPriceHighest
    case actualPriceLowest

    var id: String { rawValue }
}

struct ShoppingItemCatalogEntry: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var category: ShoppingItem.Category
    var storeName: String?
    var plannedPrice: Decimal?
    var actualPrice: Decimal?
    var isArchived: Bool
    let createdAt: Date
    var updatedAt: Date
    var isFavorite: Bool = false
    var quantity: Int = 1
    var unit: ShoppingItem.Unit = .unit
    var note: String = ""

    static func make(
        id: UUID,
        name: String,
        category: ShoppingItem.Category,
        storeName: String?,
        plannedPrice: Decimal?,
        actualPrice: Decimal?,
        isFavorite: Bool = false,
        quantity: Int = 1,
        unit: ShoppingItem.Unit = .unit,
        note: String = "",
        now: Date
    ) -> ShoppingItemCatalogEntry {
        ShoppingItemCatalogEntry(
            id: id,
            name: name,
            category: category,
            storeName: storeName,
            plannedPrice: plannedPrice,
            actualPrice: actualPrice,
            isArchived: false,
            createdAt: now,
            updatedAt: now,
            isFavorite: isFavorite,
            quantity: quantity,
            unit: unit,
            note: note
        )
    }

    func updating(
        name: String,
        category: ShoppingItem.Category,
        storeName: String?,
        plannedPrice: Decimal?,
        actualPrice: Decimal?,
        isArchived: Bool? = nil,
        isFavorite: Bool? = nil,
        quantity: Int? = nil,
        unit: ShoppingItem.Unit? = nil,
        note: String? = nil,
        updatedAt: Date
    ) -> ShoppingItemCatalogEntry {
        ShoppingItemCatalogEntry(
            id: id,
            name: name,
            category: category,
            storeName: storeName,
            plannedPrice: plannedPrice,
            actualPrice: actualPrice,
            isArchived: isArchived ?? self.isArchived,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isFavorite: isFavorite ?? self.isFavorite,
            quantity: quantity ?? self.quantity,
            unit: unit ?? self.unit,
            note: note ?? self.note
        )
    }

    var normalizedKey: String {
        let trimmedName = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
        let trimmedStore = (storeName ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
        return "\(trimmedName)|\(trimmedStore)"
    }

    static func normalizedKey(name: String, storeName: String?) -> String {
        let trimmedName = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
        let trimmedStore = (storeName ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
        return "\(trimmedName)|\(trimmedStore)"
    }
}

struct ShoppingCategoryDefinition: Codable, Equatable, Identifiable, Sendable {
    let name: String
    let iconName: String
    let colorHex: UInt32

    var id: String {
        category.id
    }

    var category: ShoppingItem.Category {
        ShoppingItem.Category(name)
    }

    init(
        name: String,
        iconName: String,
        colorHex: UInt32
    ) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.iconName = iconName
        self.colorHex = colorHex
    }

    func renamed(to name: String) -> ShoppingCategoryDefinition {
        ShoppingCategoryDefinition(
            name: name,
            iconName: iconName,
            colorHex: colorHex
        )
    }

    func updating(
        name: String,
        iconName: String,
        colorHex: UInt32
    ) -> ShoppingCategoryDefinition {
        ShoppingCategoryDefinition(
            name: name,
            iconName: iconName,
            colorHex: colorHex
        )
    }

    static let defaultDefinitions: [ShoppingCategoryDefinition] = [
        .init(name: "Produce", iconName: "leaf", colorHex: 0x10B981),
        .init(name: "Dairy", iconName: "drop", colorHex: 0x38BDF8),
        .init(name: "Protein", iconName: "fork.knife", colorHex: 0xEF4444),
        .init(name: "Pantry", iconName: "shippingbox", colorHex: 0xF59E0B),
        .init(name: "Household", iconName: "house", colorHex: 0x6366F1),
        .init(name: "Frozen", iconName: "snowflake", colorHex: 0x0EA5E9),
        .init(name: "Other", iconName: "tag", colorHex: 0x6B7280)
    ]

    static let availableIconNames = [
        "cart",
        "bag",
        "shippingbox",
        "stopwatch",
        "drop",
        "flame",
        "snowflake",
        "sparkles",
        "gift",
        "heart",
        "pawprint",
        "house",
        "hammer",
        "scissors",
        "bandage",
        "book",
        "gamecontroller",
        "desktopcomputer"
    ]

    static let availableColorHexes: [UInt32] = [
        0xFF4545,
        0xFF7A33,
        0xFFD24A,
        0x43BE82,
        0x38C4B3,
        0x38B6EB,
        0x3478F6,
        0x5E6CE6,
        0xE85BA4,
        0xB779E8,
        0xD1B271,
        0x7E8796
    ]

    static func normalizedDefinitions(
        _ definitions: [ShoppingCategoryDefinition]
    ) -> [ShoppingCategoryDefinition] {
        definitions.reduce(into: [ShoppingCategoryDefinition]()) { normalizedDefinitions, definition in
            guard
                definition.name.isEmpty == false,
                normalizedDefinitions.contains(where: { $0.category.matches(definition.category) }) == false
            else {
                return
            }

            normalizedDefinitions.append(definition)
        }
    }

    static func definition(
        for category: ShoppingItem.Category,
        in definitions: [ShoppingCategoryDefinition]
    ) -> ShoppingCategoryDefinition {
        definitions.first { $0.category.matches(category) }
            ?? ShoppingCategoryDefinition(
                name: category.rawValue,
                iconName: "tag",
                colorHex: 0x6B7280
            )
    }
}
