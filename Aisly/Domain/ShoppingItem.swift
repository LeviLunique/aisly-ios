import Foundation

struct ShoppingItem: Identifiable, Equatable, Sendable {
    enum Category: String, CaseIterable, Codable, Identifiable, Sendable {
        case produce
        case dairy
        case protein
        case pantry
        case household
        case frozen
        case other

        var id: String { rawValue }
    }

    let id: UUID
    var name: String
    var quantity: Int
    var category: Category
    var plannedPrice: Decimal?
    var actualPrice: Decimal?
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
        plannedPrice: Decimal?,
        actualPrice: Decimal?,
        sortOrder: Int,
        now: Date
    ) -> ShoppingItem {
        ShoppingItem(
            id: id,
            name: name,
            quantity: quantity,
            category: category,
            plannedPrice: plannedPrice,
            actualPrice: actualPrice,
            createdAt: now,
            updatedAt: now,
            sortOrder: sortOrder
        )
    }

    func updating(
        name: String,
        quantity: Int,
        category: Category,
        plannedPrice: Decimal?,
        actualPrice: Decimal?,
        updatedAt: Date
    ) -> ShoppingItem {
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

    func reordered(sortOrder: Int, updatedAt: Date) -> ShoppingItem {
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
