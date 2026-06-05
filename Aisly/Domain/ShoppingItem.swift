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
            sortOrder: sortOrder
        )
    }

    func updating(
        name: String,
        quantity: Int,
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
            sortOrder: sortOrder
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
            sortOrder: sortOrder
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
            sortOrder: sortOrder
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
            sortOrder: sortOrder
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
            sortOrder: sortOrder
        )
    }
}
