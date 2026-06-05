import Combine
import Foundation

@MainActor
final class ShoppingModeViewModel: ObservableObject {
    struct ItemRow: Identifiable, Equatable {
        let id: UUID
        let name: String
        let quantity: Int
        let category: ShoppingItem.Category
        let storeName: String?
        let plannedUnitPrice: Decimal?
        let actualUnitPrice: Decimal?
        let plannedTotal: Decimal?
        let actualTotal: Decimal?
        let isCompleted: Bool
        let updatedAt: Date
    }

    struct ItemSection: Identifiable, Equatable {
        let category: ShoppingItem.Category
        let items: [ItemRow]

        var id: ShoppingItem.Category.ID {
            category.id
        }
    }

    struct SessionSnapshot: Equatable {
        let listID: UUID
        let listName: String
        let plannedTotal: Decimal
        let actualTotal: Decimal
        let budgetDelta: Decimal?
        let actualPricedItemCount: Int
        let itemCount: Int
        let completedItemCount: Int
        let remainingItems: [ItemRow]
        let completedItems: [ItemRow]
        let remainingSections: [ItemSection]
        let completedSections: [ItemSection]
    }

    enum PriceEditorState: Equatable, Identifiable {
        case actualPrice(UUID)

        var id: String {
            switch self {
            case .actualPrice(let itemID):
                return "shopping-mode-actual-price-\(itemID.uuidString)"
            }
        }
    }

    enum ViewState: Equatable {
        case idle
        case loading
        case loaded(SessionSnapshot)
        case failed
    }

    @Published private(set) var state: ViewState = .idle
    @Published private(set) var priceEditorState: PriceEditorState?
    @Published private(set) var draftActualPrice = ""
    @Published private(set) var selectedCategoryFilter: ShoppingItem.Category?
    @Published private(set) var sortOption: ShoppingItem.SortOption = .category

    private let listID: UUID
    private let repository: any ShoppingListRepository
    private let now: @Sendable () -> Date
    private let locale: Locale
    private var currentList: ShoppingList?

    init(
        listID: UUID,
        repository: any ShoppingListRepository,
        now: @escaping @Sendable () -> Date = { Date() },
        locale: Locale = .autoupdatingCurrent
    ) {
        self.listID = listID
        self.repository = repository
        self.now = now
        self.locale = locale
    }

    func loadIfNeeded() async {
        guard case .idle = state else {
            return
        }

        await load()
    }

    func load() async {
        state = .loading

        do {
            let lists = try await repository.fetchLists()
            guard let list = lists.first(where: { $0.id == listID }) else {
                state = .failed
                return
            }

            currentList = list
            state = .loaded(makeSnapshot(from: list))
        } catch {
            state = .failed
        }
    }

    func toggleCompletion(id: UUID) async {
        guard
            let currentList,
            let item = currentList.items.first(where: { $0.id == id })
        else {
            return
        }

        do {
            let updatedList = try currentList.updatingItemCompletion(
                id: id,
                isCompleted: item.isCompleted == false,
                updatedAt: now()
            )
            try await persist(updatedList)
        } catch {
            dismissPriceEditor()
            state = .failed
        }
    }

    func presentActualPriceEditor(id: UUID) {
        guard let item = currentList?.items.first(where: { $0.id == id }) else {
            return
        }

        draftActualPrice = draftString(for: item.actualPrice)
        priceEditorState = .actualPrice(id)
    }

    func dismissPriceEditor() {
        priceEditorState = nil
        draftActualPrice = ""
    }

    func updateDraftActualPrice(_ draftActualPrice: String) {
        self.draftActualPrice = draftActualPrice
    }

    func updateSelectedCategoryFilter(_ category: ShoppingItem.Category?) {
        selectedCategoryFilter = category
        refreshSnapshot()
    }

    func updateSortOption(_ sortOption: ShoppingItem.SortOption) {
        self.sortOption = sortOption
        refreshSnapshot()
    }

    func applyPlannedPriceSuggestion() {
        guard let plannedPrice = currentEditingItem?.plannedPrice else {
            return
        }

        draftActualPrice = draftString(for: plannedPrice)
    }

    func saveActualPriceDraft() async {
        guard
            let currentList,
            case .actualPrice(let itemID) = priceEditorState,
            isDraftSubmissionDisabled == false
        else {
            return
        }

        do {
            let updatedList = try currentList.updatingItemActualPrice(
                id: itemID,
                actualPrice: normalizedDraftActualPrice,
                updatedAt: now()
            )
            try await persist(updatedList)
            dismissPriceEditor()
        } catch {
            dismissPriceEditor()
            state = .failed
        }
    }

    var plannedPriceSuggestion: Decimal? {
        currentEditingItem?.plannedPrice
    }

    var availableCategories: [ShoppingItem.Category] {
        guard let currentList else {
            return ShoppingItem.Category.defaultCategories
        }

        return availableCategories(from: currentList)
    }

    var currentEditingItemName: String? {
        currentEditingItem?.name
    }

    var isDraftSubmissionDisabled: Bool {
        guard let currentEditingItem else {
            return true
        }

        return isValidPriceDraft(draftActualPrice) == false ||
            currentEditingItem.actualPrice == normalizedDraftActualPrice
    }

    private var currentEditingItem: ShoppingItem? {
        guard case .actualPrice(let itemID) = priceEditorState else {
            return nil
        }

        return currentList?.items.first(where: { $0.id == itemID })
    }

    private var normalizedDraftActualPrice: Decimal? {
        normalizedPrice(from: draftActualPrice)
    }

    private func makeSnapshot(from list: ShoppingList) -> SessionSnapshot {
        let visibleItems = sortedItems(filteredItems(from: list))
        let remainingItems = visibleItems.filter { $0.isCompleted == false }.map(ItemRow.init)
        let completedItems = visibleItems.filter(\.isCompleted).map(ItemRow.init)

        return SessionSnapshot(
            listID: list.id,
            listName: list.name,
            plannedTotal: list.plannedTotal,
            actualTotal: list.actualTotal,
            budgetDelta: list.budgetDelta,
            actualPricedItemCount: list.actualPricedItemCount,
            itemCount: list.items.count,
            completedItemCount: list.completedItemCount,
            remainingItems: remainingItems,
            completedItems: completedItems,
            remainingSections: makeItemSections(from: visibleItems.filter { $0.isCompleted == false }),
            completedSections: makeItemSections(from: visibleItems.filter(\.isCompleted))
        )
    }

    private func makeItemSections(from items: [ShoppingItem]) -> [ItemSection] {
        let groupedItems = Dictionary(grouping: items, by: \.category)
        return orderedCategories(for: Array(groupedItems.keys)).compactMap { category in
            guard let categoryItems = groupedItems[category] else {
                return nil
            }

            return ItemSection(
                category: category,
                items: sortedItems(categoryItems).map(ItemRow.init)
            )
        }
    }

    private func filteredItems(from list: ShoppingList) -> [ShoppingItem] {
        guard let selectedCategoryFilter else {
            return list.items
        }

        return list.items.filter { $0.category.matches(selectedCategoryFilter) }
    }

    private func sortedItems(_ items: [ShoppingItem]) -> [ShoppingItem] {
        items.sorted(by: itemComparator)
    }

    private var itemComparator: (ShoppingItem, ShoppingItem) -> Bool {
        { lhs, rhs in
            switch self.sortOption {
            case .category:
                return self.categorySortedComparator(lhs, rhs)
            case .name:
                return self.localizedCompare(lhs.name, rhs.name) ?? self.itemSortComparator(lhs, rhs)
            case .plannedPrice:
                return self.priceSortedComparator(lhs, rhs, price: \.plannedTotal)
            case .actualPrice:
                return self.priceSortedComparator(lhs, rhs, price: \.actualTotal)
            }
        }
    }

    private func categorySortedComparator(_ lhs: ShoppingItem, _ rhs: ShoppingItem) -> Bool {
        if lhs.category.matches(rhs.category) == false {
            return categoryComparator(lhs.category, rhs.category)
        }

        return itemSortComparator(lhs, rhs)
    }

    private func priceSortedComparator(
        _ lhs: ShoppingItem,
        _ rhs: ShoppingItem,
        price: KeyPath<ShoppingItem, Decimal?>
    ) -> Bool {
        let lhsPrice = lhs[keyPath: price]
        let rhsPrice = rhs[keyPath: price]

        switch (lhsPrice, rhsPrice) {
        case let (.some(lhsPrice), .some(rhsPrice)) where lhsPrice != rhsPrice:
            return lhsPrice < rhsPrice
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        default:
            return localizedCompare(lhs.name, rhs.name) ?? itemSortComparator(lhs, rhs)
        }
    }

    private func categoryComparator(
        _ lhs: ShoppingItem.Category,
        _ rhs: ShoppingItem.Category
    ) -> Bool {
        let lhsRank = categoryRank(for: lhs)
        let rhsRank = categoryRank(for: rhs)

        if lhsRank != rhsRank {
            return lhsRank < rhsRank
        }

        return localizedCompare(lhs.rawValue, rhs.rawValue) ?? (lhs.rawValue < rhs.rawValue)
    }

    private func categoryRank(for category: ShoppingItem.Category) -> Int {
        availableCategories.firstIndex { $0.matches(category) } ?? Int.max
    }

    private func orderedCategories(
        for categories: [ShoppingItem.Category]
    ) -> [ShoppingItem.Category] {
        let normalizedCategories = ShoppingList.normalizedCategories(categories)
        let orderedExistingCategories = availableCategories.filter { availableCategory in
            normalizedCategories.contains { $0.matches(availableCategory) }
        }
        let remainingCategories = normalizedCategories.filter { category in
            orderedExistingCategories.contains { $0.matches(category) } == false
        }

        return orderedExistingCategories + remainingCategories.sorted(by: categoryComparator)
    }

    private func availableCategories(from list: ShoppingList) -> [ShoppingItem.Category] {
        ShoppingList.normalizedCategories(list.categories + list.items.map(\.category))
    }

    private func localizedCompare(_ lhs: String, _ rhs: String) -> Bool? {
        let comparison = lhs.localizedCaseInsensitiveCompare(rhs)
        guard comparison != .orderedSame else {
            return nil
        }

        return comparison == .orderedAscending
    }

    private var itemSortComparator: (ShoppingItem, ShoppingItem) -> Bool {
        { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.createdAt < rhs.createdAt
            }

            return lhs.sortOrder < rhs.sortOrder
        }
    }

    private func draftString(for price: Decimal?) -> String {
        guard let price else {
            return ""
        }

        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2

        return formatter.string(from: price as NSDecimalNumber) ?? ""
    }

    private func isValidPriceDraft(_ priceDraft: String) -> Bool {
        let trimmedDraft = priceDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedDraft.isEmpty || normalizedPrice(from: trimmedDraft) != nil
    }

    private func normalizedPrice(from priceDraft: String) -> Decimal? {
        let trimmedDraft = priceDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedDraft.isEmpty == false else {
            return nil
        }

        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.generatesDecimalNumbers = true

        let fallbackInputs = [trimmedDraft]
            + [trimmedDraft.replacingOccurrences(of: ",", with: ".")]
            + [trimmedDraft.replacingOccurrences(of: ".", with: locale.decimalSeparator ?? ".")]

        for input in fallbackInputs {
            guard let number = formatter.number(from: input) else {
                continue
            }

            let decimal = number.decimalValue
            guard decimal >= .zero else {
                return nil
            }

            return decimal
        }

        return nil
    }

    private func refreshSnapshot() {
        guard let currentList else {
            return
        }

        if
            let selectedCategoryFilter,
            availableCategories.contains(where: { $0.matches(selectedCategoryFilter) }) == false
        {
            self.selectedCategoryFilter = nil
        }

        state = .loaded(makeSnapshot(from: currentList))
    }

    private func persist(_ updatedList: ShoppingList) async throws {
        let allLists = try await repository.fetchLists()
        let updatedLists = try replace(listID: updatedList.id, in: allLists, with: updatedList)
        try await repository.saveLists(updatedLists)
        currentList = updatedList
        state = .loaded(makeSnapshot(from: updatedList))
    }

    private func replace(
        listID: UUID,
        in lists: [ShoppingList],
        with updatedList: ShoppingList
    ) throws -> [ShoppingList] {
        guard let index = lists.firstIndex(where: { $0.id == listID }) else {
            throw ShoppingModeViewModelError.listNotFound
        }

        var updatedLists = lists
        updatedLists[index] = updatedList
        return updatedLists
    }
}

private extension ShoppingModeViewModel.ItemRow {
    init(item: ShoppingItem) {
        id = item.id
        name = item.name
        quantity = item.quantity
        category = item.category
        storeName = item.storeName
        plannedUnitPrice = item.plannedPrice
        actualUnitPrice = item.actualPrice
        plannedTotal = item.plannedTotal
        actualTotal = item.actualTotal
        isCompleted = item.isCompleted
        updatedAt = item.updatedAt
    }
}

private enum ShoppingModeViewModelError: Error {
    case listNotFound
}
