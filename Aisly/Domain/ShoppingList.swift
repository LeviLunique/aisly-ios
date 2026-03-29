import Foundation

struct ShoppingList: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    let createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    static func make(
        id: UUID,
        name: String,
        now: Date
    ) -> ShoppingList {
        ShoppingList(
            id: id,
            name: name,
            createdAt: now,
            updatedAt: now,
            isArchived: false
        )
    }

    func renamed(to name: String, updatedAt: Date) -> ShoppingList {
        ShoppingList(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isArchived: isArchived
        )
    }

    func archived(updatedAt: Date) -> ShoppingList {
        ShoppingList(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isArchived: true
        )
    }
}
