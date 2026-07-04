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

    static let defaultIconName = "cart"
    static let defaultColorHex: UInt32 = 0x14B8A6

    static let availableIconNames: [String] = [
        "cart",
        "basket",
        "bag",
        ["list", "bullet", "clipboard"].joined(separator: "."),
        "tag",
        "leaf",
        "fork.knife",
        "house",
        "gift",
        "heart",
        "star",
        "flame"
    ]

    static let availableColorHexes: [UInt32] = [
        0x14B8A6,
        0x10B981,
        0x84CC16,
        0xF59E0B,
        0xEF4444,
        0xEC4899,
        0x8B5CF6,
        0x6366F1,
        0x0EA5E9,
        0x64748B
    ]

    let id: UUID
    var name: String
    let createdAt: Date
    var updatedAt: Date
    var isArchived: Bool
    var budget: Decimal? = nil
    var iconName: String = ShoppingList.defaultIconName
    var colorHex: UInt32 = ShoppingList.defaultColorHex
    var categories: [ShoppingItem.Category] = ShoppingItem.Category.defaultCategories
    var items: [ShoppingItem] = []
    var templateConfiguration: TemplateConfiguration? = nil
    var sourceTemplateID: UUID? = nil
    var isPinned: Bool = false

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
        guard let budget, actualPricedItemCount > 0 else {
            return nil
        }

        return budget - actualTotal
    }

    var planDelta: Decimal? {
        guard actualPricedItemCount > 0 else {
            return nil
        }

        return plannedTotal - actualTotal
    }

    var purchasedItemCount: Int {
        completedItemCount
    }

    var missingActualPurchasedItemCount: Int {
        items.reduce(into: 0) { count, item in
            if item.isCompleted && item.actualPrice == nil {
                count += 1
            }
        }
    }

    /// Number of items that still have no actual price recorded. Drives the
    /// Home "N no price" warning badge on budgeted lists.
    var itemsMissingActualPriceCount: Int {
        items.reduce(into: 0) { count, item in
            if item.actualPrice == nil {
                count += 1
            }
        }
    }

    static func make(
        id: UUID,
        name: String,
        now: Date,
        budget: Decimal? = nil,
        iconName: String = ShoppingList.defaultIconName,
        colorHex: UInt32 = ShoppingList.defaultColorHex,
        templateConfiguration: TemplateConfiguration? = nil,
        categories: [ShoppingItem.Category] = ShoppingItem.Category.defaultCategories,
        items: [ShoppingItem] = []
    ) -> ShoppingList {
        ShoppingList(
            id: id,
            name: name,
            createdAt: now,
            updatedAt: now,
            isArchived: false,
            budget: budget,
            iconName: iconName,
            colorHex: colorHex,
            categories: normalizedCategories(categories + items.map(\.category)),
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
            budget: budget,
            iconName: iconName,
            colorHex: colorHex,
            categories: categories,
            items: items,
            templateConfiguration: templateConfiguration,
            sourceTemplateID: sourceTemplateID,
            isPinned: isPinned
        )
    }

    func updatingAppearance(
        iconName: String,
        colorHex: UInt32,
        updatedAt: Date
    ) -> ShoppingList {
        ShoppingList(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isArchived: isArchived,
            budget: budget,
            iconName: iconName,
            colorHex: colorHex,
            categories: categories,
            items: items,
            templateConfiguration: templateConfiguration,
            sourceTemplateID: sourceTemplateID,
            isPinned: isPinned
        )
    }

    func archived(updatedAt: Date) -> ShoppingList {
        ShoppingList(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isArchived: true,
            budget: budget,
            iconName: iconName,
            colorHex: colorHex,
            categories: categories,
            items: items,
            templateConfiguration: templateConfiguration,
            sourceTemplateID: sourceTemplateID,
            isPinned: isPinned
        )
    }

    func detachingSourceTemplate() -> ShoppingList {
        guard sourceTemplateID != nil else {
            return self
        }

        var detached = self
        detached.sourceTemplateID = nil
        return detached
    }

    func unarchived(updatedAt: Date) -> ShoppingList {
        ShoppingList(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isArchived: false,
            budget: budget,
            iconName: iconName,
            colorHex: colorHex,
            categories: categories,
            items: items,
            templateConfiguration: templateConfiguration,
            sourceTemplateID: sourceTemplateID,
            isPinned: isPinned
        )
    }

    func pinned(_ isPinned: Bool, updatedAt: Date) -> ShoppingList {
        var updated = self
        updated.isPinned = isPinned
        updated.updatedAt = updatedAt
        return updated
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
            budget: budget,
            iconName: iconName,
            colorHex: colorHex,
            categories: categories,
            items: templateItems,
            templateConfiguration: .init(recurrence: recurrence),
            sourceTemplateID: nil
        )
    }

    func generatingListFromTemplate(
        id: UUID,
        makeItemID: () -> UUID,
        updatedAt: Date,
        iconName: String? = nil,
        colorHex: UInt32? = nil,
        name overrideName: String? = nil
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
            name: overrideName ?? name,
            createdAt: updatedAt,
            updatedAt: updatedAt,
            isArchived: false,
            budget: budget,
            iconName: iconName ?? self.iconName,
            colorHex: colorHex ?? self.colorHex,
            categories: categories,
            items: generatedItems,
            templateConfiguration: nil,
            sourceTemplateID: self.id
        )
    }

    func addingItem(
        id: UUID,
        name: String,
        quantity: Int,
        unit: ShoppingItem.Unit = .unit,
        note: String = "",
        isFavorite: Bool = false,
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
                unit: unit,
                note: note,
                isFavorite: isFavorite,
                category: category,
                storeName: storeName,
                plannedPrice: plannedPrice,
                actualPrice: actualPrice,
                isCompleted: false,
                sortOrder: nextSortOrder,
                now: updatedAt
            )
        )

        return replacingItems(
            updatedItems,
            categories: ShoppingList.normalizedCategories(categories + [category]),
            updatedAt: updatedAt
        )
    }

    func updatingItem(
        id: UUID,
        name: String,
        quantity: Int,
        unit: ShoppingItem.Unit = .unit,
        note: String = "",
        isFavorite: Bool = false,
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
            unit: unit,
            note: note,
            isFavorite: isFavorite,
            category: category,
            storeName: storeName,
            plannedPrice: plannedPrice,
            actualPrice: actualPrice,
            isCompleted: updatedItems[index].isCompleted,
            updatedAt: updatedAt
        )

        return replacingItems(
            updatedItems,
            categories: ShoppingList.normalizedCategories(categories + [category]),
            updatedAt: updatedAt
        )
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

    func addingCategory(_ category: ShoppingItem.Category, updatedAt: Date) -> ShoppingList {
        replacingItems(
            items,
            categories: ShoppingList.normalizedCategories(categories + [category]),
            updatedAt: updatedAt
        )
    }

    func removingCategory(
        _ category: ShoppingItem.Category,
        fallback: ShoppingItem.Category,
        updatedAt: Date
    ) -> ShoppingList {
        let categoryExistsInList = categories.contains { $0.matches(category) }
        let itemsUsingCategory = items.contains { $0.category.matches(category) }

        guard categoryExistsInList || itemsUsingCategory else {
            return self
        }

        let updatedCategories = categories.filter { $0.matches(category) == false }
        let updatedItems = items.map { item in
            guard item.category.matches(category) else {
                return item
            }

            return item.updating(
                name: item.name,
                quantity: item.quantity,
                unit: item.unit,
                note: item.note,
                isFavorite: item.isFavorite,
                category: fallback,
                storeName: item.storeName,
                plannedPrice: item.plannedPrice,
                actualPrice: item.actualPrice,
                isCompleted: item.isCompleted,
                updatedAt: updatedAt
            )
        }

        return replacingItems(
            updatedItems,
            categories: ShoppingList.normalizedCategories(updatedCategories + updatedItems.map(\.category)),
            updatedAt: updatedAt
        )
    }

    func renamingCategory(
        _ category: ShoppingItem.Category,
        to renamedCategory: ShoppingItem.Category,
        updatedAt: Date
    ) -> ShoppingList {
        let updatedCategories = categories.map { existingCategory in
            existingCategory.matches(category) ? renamedCategory : existingCategory
        }
        let categoryExistsInList = categories.contains { $0.matches(category) }
        let categoriesWithRenameTarget = categoryExistsInList
            ? updatedCategories
            : updatedCategories + [renamedCategory]
        let updatedItems = items.map { item in
            guard item.category.matches(category) else {
                return item
            }

            return item.updating(
                name: item.name,
                quantity: item.quantity,
                unit: item.unit,
                note: item.note,
                isFavorite: item.isFavorite,
                category: renamedCategory,
                storeName: item.storeName,
                plannedPrice: item.plannedPrice,
                actualPrice: item.actualPrice,
                isCompleted: item.isCompleted,
                updatedAt: updatedAt
            )
        }

        return replacingItems(
            updatedItems,
            categories: ShoppingList.normalizedCategories(categoriesWithRenameTarget + updatedItems.map(\.category)),
            updatedAt: updatedAt
        )
    }

    func replacingItems(_ items: [ShoppingItem], updatedAt: Date) -> ShoppingList {
        replacingItems(
            items,
            categories: ShoppingList.normalizedCategories(categories + items.map(\.category)),
            updatedAt: updatedAt
        )
    }

    func replacingItems(
        _ items: [ShoppingItem],
        categories: [ShoppingItem.Category],
        updatedAt: Date
    ) -> ShoppingList {
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
            items: items,
            templateConfiguration: templateConfiguration,
            sourceTemplateID: sourceTemplateID,
            isPinned: isPinned
        )
    }

    static func reindexedItems(_ items: [ShoppingItem], updatedAt: Date) -> [ShoppingItem] {
        items.enumerated().map { index, item in
            item.reordered(sortOrder: index, updatedAt: updatedAt)
        }
    }

    static func normalizedCategories(_ categories: [ShoppingItem.Category]) -> [ShoppingItem.Category] {
        categories.reduce(into: [ShoppingItem.Category]()) { normalizedCategories, category in
            guard normalizedCategories.contains(where: { $0.matches(category) }) == false else {
                return
            }

            normalizedCategories.append(category)
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

struct PurchaseHistoryEntry: Codable, Equatable, Identifiable, Sendable {
    struct SectionSnapshot: Codable, Equatable, Identifiable, Sendable {
        let id: String
        let name: String
        let items: [ItemSnapshot]

        init(name: String, items: [ItemSnapshot]) {
            self.id = ShoppingItem.Category.normalizedIdentifier(for: name)
            self.name = name
            self.items = items
        }
    }

    struct ItemSnapshot: Codable, Equatable, Identifiable, Sendable {
        let id: UUID
        let name: String
        let quantity: Int
        let sectionName: String
        let storeName: String?
        let plannedPrice: Decimal?
        let actualPrice: Decimal?
        let isPurchased: Bool
        // Optional with a default so the synthesized memberwise init keeps
        // old call sites compiling and old persisted JSON still decodes.
        var unit: ShoppingItem.Unit? = nil

        var plannedTotal: Decimal? {
            plannedPrice.map { $0 * Decimal(quantity) }
        }

        var actualTotal: Decimal? {
            actualPrice.map { $0 * Decimal(quantity) }
        }
    }

    let id: UUID
    let sourceListID: UUID
    let sourceTemplateID: UUID?
    let name: String
    let finishedAt: Date
    let budget: Decimal?
    let plannedTotal: Decimal
    let actualTotal: Decimal
    let budgetDelta: Decimal?
    let planDelta: Decimal?
    let purchasedItemCount: Int
    let missingActualPriceCount: Int
    let sections: [SectionSnapshot]
    /// Total items on the source list when the purchase was finished — drives
    /// the "12 of 18 purchased" summary. Optional so legacy snapshots decode.
    var totalItemCount: Int? = nil

    static func make(
        id: UUID,
        from list: ShoppingList,
        finishedAt: Date
    ) -> PurchaseHistoryEntry {
        let purchasedItems = list.items
            .filter(\.isCompleted)
            .sorted { lhs, rhs in
                if lhs.sortOrder == rhs.sortOrder {
                    return lhs.createdAt < rhs.createdAt
                }

                return lhs.sortOrder < rhs.sortOrder
            }

        let itemSnapshots = purchasedItems.map { item in
            ItemSnapshot(
                id: item.id,
                name: item.name,
                quantity: item.quantity,
                sectionName: item.category.rawValue,
                storeName: item.storeName,
                plannedPrice: item.plannedPrice,
                actualPrice: item.actualPrice,
                isPurchased: item.isCompleted,
                unit: item.unit
            )
        }
        let sections = Dictionary(grouping: itemSnapshots, by: \.sectionName)
            .map { sectionName, items in
                SectionSnapshot(name: sectionName, items: items)
            }
            .sorted { lhs, rhs in
                lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }

        let plannedTotal = itemSnapshots.reduce(into: Decimal.zero) { total, item in
            total += item.plannedTotal ?? .zero
        }
        let actualTotal = itemSnapshots.reduce(into: Decimal.zero) { total, item in
            total += item.actualTotal ?? .zero
        }
        let actualPricedItemCount = itemSnapshots.reduce(into: 0) { count, item in
            if item.actualPrice != nil {
                count += 1
            }
        }

        return PurchaseHistoryEntry(
            id: id,
            sourceListID: list.id,
            sourceTemplateID: list.sourceTemplateID,
            name: list.name,
            finishedAt: finishedAt,
            budget: list.budget,
            plannedTotal: plannedTotal,
            actualTotal: actualTotal,
            budgetDelta: actualPricedItemCount > 0 ? list.budget.map { $0 - actualTotal } : nil,
            planDelta: actualPricedItemCount > 0 ? plannedTotal - actualTotal : nil,
            purchasedItemCount: itemSnapshots.count,
            missingActualPriceCount: itemSnapshots.reduce(into: 0) { count, item in
                if item.actualPrice == nil {
                    count += 1
                }
            },
            sections: sections,
            totalItemCount: list.items.count
        )
    }

    func repeatingAsList(
        id: UUID,
        makeItemID: () -> UUID,
        finishedAt: Date,
        useActualPricesAsPlan: Bool = false
    ) -> ShoppingList {
        let items = sections
            .flatMap(\.items)
            .enumerated()
            .map { index, item in
                ShoppingItem.make(
                    id: makeItemID(),
                    name: item.name,
                    quantity: item.quantity,
                    unit: item.unit ?? .unit,
                    category: ShoppingItem.Category(item.sectionName),
                    storeName: item.storeName,
                    plannedPrice: useActualPricesAsPlan ? item.actualPrice ?? item.plannedPrice : item.plannedPrice,
                    actualPrice: nil,
                    sortOrder: index,
                    now: finishedAt
                )
            }

        return ShoppingList.make(
            id: id,
            name: name,
            now: finishedAt,
            budget: budget,
            categories: ShoppingList.normalizedCategories(items.map(\.category)),
            items: items
        )
    }
}
