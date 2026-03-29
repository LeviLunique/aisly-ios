import Foundation

struct ShoppingList: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    let createdAt: Date
    var updatedAt: Date
    var isArchived: Bool
    var items: [ShoppingItem] = []

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
            isArchived: false,
            items: []
        )
    }

    func renamed(to name: String, updatedAt: Date) -> ShoppingList {
        ShoppingList(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isArchived: isArchived,
            items: items
        )
    }

    func archived(updatedAt: Date) -> ShoppingList {
        ShoppingList(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isArchived: true,
            items: items
        )
    }

    func addingItem(
        id: UUID,
        name: String,
        quantity: Int,
        category: ShoppingItem.Category,
        updatedAt: Date
    ) -> ShoppingList {
        let nextSortOrder = (items.map(\.sortOrder).max() ?? -1) + 1
        var updatedItems = items
        updatedItems.append(
            ShoppingItem.make(
                id: id,
                name: name,
                quantity: quantity,
                category: category,
                sortOrder: nextSortOrder,
                now: updatedAt
            )
        )

        return replacingItems(updatedItems, updatedAt: updatedAt)
    }

    func updatingItem(
        id: UUID,
        name: String,
        quantity: Int,
        category: ShoppingItem.Category,
        updatedAt: Date
    ) throws -> ShoppingList {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            throw ShoppingListMutationError.itemNotFound
        }

        var updatedItems = items
        updatedItems[index] = updatedItems[index].updating(
            name: name,
            quantity: quantity,
            category: category,
            updatedAt: updatedAt
        )

        return replacingItems(updatedItems, updatedAt: updatedAt)
    }

    func deletingItem(id: UUID, updatedAt: Date) throws -> ShoppingList {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            throw ShoppingListMutationError.itemNotFound
        }

        var updatedItems = items
        updatedItems.remove(at: index)

        return replacingItems(
            ShoppingList.reindexedItems(updatedItems, updatedAt: updatedAt),
            updatedAt: updatedAt
        )
    }

    func replacingItems(_ items: [ShoppingItem], updatedAt: Date) -> ShoppingList {
        ShoppingList(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isArchived: isArchived,
            items: items
        )
    }

    static func reindexedItems(_ items: [ShoppingItem], updatedAt: Date) -> [ShoppingItem] {
        items.enumerated().map { index, item in
            item.reordered(sortOrder: index, updatedAt: updatedAt)
        }
    }
}

enum ShoppingListMutationError: Error {
    case itemNotFound
}
