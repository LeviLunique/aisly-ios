import Foundation

struct ShoppingList: Identifiable, Equatable, Sendable {
    enum TemplateRecurrence: String, CaseIterable, Codable, Identifiable, Sendable {
        case weekly
        case biweekly
        case monthly

        var id: String { rawValue }
    }

    struct TemplateConfiguration: Equatable, Codable, Sendable {
        let recurrence: TemplateRecurrence
    }

    let id: UUID
    var name: String
    let createdAt: Date
    var updatedAt: Date
    var isArchived: Bool
    var items: [ShoppingItem] = []
    var templateConfiguration: TemplateConfiguration? = nil

    var isTemplate: Bool {
        templateConfiguration != nil
    }

    var templateRecurrence: TemplateRecurrence? {
        templateConfiguration?.recurrence
    }

    var plannedTotal: Decimal {
        items.reduce(into: Decimal.zero) { total, item in
            total += item.plannedTotal ?? .zero
        }
    }

    var actualTotal: Decimal {
        items.reduce(into: Decimal.zero) { total, item in
            total += item.actualTotal ?? .zero
        }
    }

    var actualPricedItemCount: Int {
        items.reduce(into: 0) { count, item in
            if item.actualPrice != nil {
                count += 1
            }
        }
    }

    var completedItemCount: Int {
        items.reduce(into: 0) { count, item in
            if item.isCompleted {
                count += 1
            }
        }
    }

    var budgetDelta: Decimal? {
        guard actualPricedItemCount > 0 else {
            return nil
        }

        return actualTotal - plannedTotal
    }

    static func make(
        id: UUID,
        name: String,
        now: Date,
        templateConfiguration: TemplateConfiguration? = nil,
        items: [ShoppingItem] = []
    ) -> ShoppingList {
        ShoppingList(
            id: id,
            name: name,
            createdAt: now,
            updatedAt: now,
            isArchived: false,
            items: items,
            templateConfiguration: templateConfiguration
        )
    }

    func renamed(to name: String, updatedAt: Date) -> ShoppingList {
        ShoppingList(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isArchived: isArchived,
            items: items,
            templateConfiguration: templateConfiguration
        )
    }

    func archived(updatedAt: Date) -> ShoppingList {
        ShoppingList(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isArchived: true,
            items: items,
            templateConfiguration: templateConfiguration
        )
    }

    func makingTemplate(
        id: UUID,
        name: String,
        recurrence: TemplateRecurrence,
        makeItemID: () -> UUID,
        updatedAt: Date
    ) -> ShoppingList {
        let templateItems = items
            .sorted(by: ShoppingList.itemSortComparator)
            .enumerated()
            .map { index, item in
                item.copiedForTemplateReuse(
                    id: makeItemID(),
                    updatedAt: updatedAt,
                    sortOrder: index
                )
            }

        return ShoppingList(
            id: id,
            name: name,
            createdAt: updatedAt,
            updatedAt: updatedAt,
            isArchived: false,
            items: templateItems,
            templateConfiguration: .init(recurrence: recurrence)
        )
    }

    func generatingListFromTemplate(
        id: UUID,
        makeItemID: () -> UUID,
        updatedAt: Date
    ) -> ShoppingList {
        let generatedItems = items
            .sorted(by: ShoppingList.itemSortComparator)
            .enumerated()
            .map { index, item in
                item.copiedForTemplateReuse(
                    id: makeItemID(),
                    updatedAt: updatedAt,
                    sortOrder: index
                )
            }

        return ShoppingList(
            id: id,
            name: name,
            createdAt: updatedAt,
            updatedAt: updatedAt,
            isArchived: false,
            items: generatedItems,
            templateConfiguration: nil
        )
    }

    func addingItem(
        id: UUID,
        name: String,
        quantity: Int,
        category: ShoppingItem.Category,
        storeName: String?,
        plannedPrice: Decimal?,
        actualPrice: Decimal?,
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
                storeName: storeName,
                plannedPrice: plannedPrice,
                actualPrice: actualPrice,
                isCompleted: false,
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
        storeName: String?,
        plannedPrice: Decimal?,
        actualPrice: Decimal?,
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
            storeName: storeName,
            plannedPrice: plannedPrice,
            actualPrice: actualPrice,
            isCompleted: updatedItems[index].isCompleted,
            updatedAt: updatedAt
        )

        return replacingItems(updatedItems, updatedAt: updatedAt)
    }

    func updatingItemCompletion(
        id: UUID,
        isCompleted: Bool,
        updatedAt: Date
    ) throws -> ShoppingList {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            throw ShoppingListMutationError.itemNotFound
        }

        var updatedItems = items
        updatedItems[index] = updatedItems[index].updatingCompletion(
            isCompleted: isCompleted,
            updatedAt: updatedAt
        )

        return replacingItems(updatedItems, updatedAt: updatedAt)
    }

    func updatingItemActualPrice(
        id: UUID,
        actualPrice: Decimal?,
        updatedAt: Date
    ) throws -> ShoppingList {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            throw ShoppingListMutationError.itemNotFound
        }

        var updatedItems = items
        updatedItems[index] = updatedItems[index].updatingActualPrice(
            actualPrice,
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
            items: items,
            templateConfiguration: templateConfiguration
        )
    }

    static func reindexedItems(_ items: [ShoppingItem], updatedAt: Date) -> [ShoppingItem] {
        items.enumerated().map { index, item in
            item.reordered(sortOrder: index, updatedAt: updatedAt)
        }
    }

    private static var itemSortComparator: (ShoppingItem, ShoppingItem) -> Bool {
        { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.createdAt < rhs.createdAt
            }

            return lhs.sortOrder < rhs.sortOrder
        }
    }
}

enum ShoppingListMutationError: Error {
    case itemNotFound
}
