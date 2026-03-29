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
    let createdAt: Date
    var updatedAt: Date
    var sortOrder: Int

    static func make(
        id: UUID,
        name: String,
        quantity: Int,
        category: Category,
        sortOrder: Int,
        now: Date
    ) -> ShoppingItem {
        ShoppingItem(
            id: id,
            name: name,
            quantity: quantity,
            category: category,
            createdAt: now,
            updatedAt: now,
            sortOrder: sortOrder
        )
    }

    func updating(
        name: String,
        quantity: Int,
        category: Category,
        updatedAt: Date
    ) -> ShoppingItem {
        ShoppingItem(
            id: id,
            name: name,
            quantity: quantity,
            category: category,
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
            createdAt: createdAt,
            updatedAt: updatedAt,
            sortOrder: sortOrder
        )
    }
}
