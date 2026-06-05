import Combine
import Foundation

@MainActor
final class ListDetailViewModel: ObservableObject {
    struct QuickEntrySuggestion: Identifiable, Equatable {
        let id: String
        let name: String
        let quantity: Int
        let category: ShoppingItem.Category
        let storeName: String?
        let plannedPrice: Decimal?
        let usageCount: Int
        let lastUsedAt: Date
    }

    struct StoreSuggestion: Identifiable, Equatable {
        let id: String
        let name: String
        let usageCount: Int
        let lastUsedAt: Date
    }

    struct PriceMemorySuggestion: Equatable {
        enum Kind: Equatable {
            case actual
            case planned
        }

        let storeName: String
        let price: Decimal
        let kind: Kind
        let lastUsedAt: Date
    }

    struct ItemRow: Identifiable, Equatable {
        let id: UUID
        let name: String
        let quantity: Int
        let category: ShoppingItem.Category
        let storeName: String?
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

    struct ListSnapshot: Equatable {
        let listID: UUID
        let listName: String
        let plannedTotal: Decimal
        let actualTotal: Decimal
        let budgetDelta: Decimal?
        let actualPricedItemCount: Int
        let items: [ItemRow]
        let itemSections: [ItemSection]
    }

    enum EditorMode: Equatable, Identifiable {
        case create
        case edit(UUID)

        var id: String {
            switch self {
            case .create:
                return "create-item"
            case .edit(let id):
                return "edit-item-\(id.uuidString)"
            }
        }
    }

    enum ViewState: Equatable {
        case idle
        case loading
        case loaded(ListSnapshot)
        case failed
    }

    @Published private(set) var state: ViewState = .idle
    @Published private(set) var editorMode: EditorMode?
    @Published private(set) var draftName = ""
    @Published private(set) var draftQuantity = 1
    @Published private(set) var draftCategory: ShoppingItem.Category = .produce
    @Published private(set) var draftStoreName = ""
    @Published private(set) var draftPlannedPrice = ""
    @Published private(set) var draftActualPrice = ""
    @Published private(set) var draftNewCategoryName = ""
    @Published private(set) var isCategoryManagerPresented = false
    @Published private(set) var selectedCategoryForRename: ShoppingItem.Category?
    @Published private(set) var draftRenamedCategoryName = ""
    @Published private(set) var selectedCategoryFilter: ShoppingItem.Category?
    @Published private(set) var sortOption: ShoppingItem.SortOption = .category

    let listID: UUID
    private let repository: any ShoppingListRepository
    private let now: @Sendable () -> Date
    private let makeUUID: @Sendable () -> UUID
    private let locale: Locale
    private var allLists: [ShoppingList] = []
    private var currentList: ShoppingList?

    init(
        listID: UUID,
        repository: any ShoppingListRepository,
        now: @escaping @Sendable () -> Date = { Date() },
        makeUUID: @escaping @Sendable () -> UUID = { UUID() },
        locale: Locale = .autoupdatingCurrent
    ) {
        self.listID = listID
        self.repository = repository
        self.now = now
        self.makeUUID = makeUUID
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

            allLists = lists
            currentList = list
            state = .loaded(makeSnapshot(from: list))
        } catch {
            state = .failed
        }
    }

    func presentCreateItem() {
        draftName = ""
        draftQuantity = 1
        draftCategory = suggestedCategoryForNewItem
        draftStoreName = ""
        draftPlannedPrice = ""
        draftActualPrice = ""
        draftNewCategoryName = ""
        editorMode = .create
    }

    func presentEditItem(id: UUID) {
        guard let item = currentList?.items.first(where: { $0.id == id }) else {
            return
        }

        draftName = item.name
        draftQuantity = item.quantity
        draftCategory = item.category
        draftStoreName = item.storeName ?? ""
        draftPlannedPrice = draftString(for: item.plannedPrice)
        draftActualPrice = draftString(for: item.actualPrice)
        draftNewCategoryName = ""
        editorMode = .edit(id)
    }

    func dismissEditor() {
        editorMode = nil
        draftName = ""
        draftQuantity = 1
        draftCategory = .produce
        draftStoreName = ""
        draftPlannedPrice = ""
        draftActualPrice = ""
        draftNewCategoryName = ""
    }

    func updateDraftName(_ draftName: String) {
        self.draftName = draftName
    }

    func updateDraftQuantity(_ quantity: Int) {
        draftQuantity = max(1, quantity)
    }

    func updateDraftCategory(_ category: ShoppingItem.Category) {
        draftCategory = category
        draftNewCategoryName = ""
    }

    func updateDraftStoreName(_ storeName: String) {
        draftStoreName = storeName
    }

    func updateDraftPlannedPrice(_ plannedPrice: String) {
        draftPlannedPrice = plannedPrice
    }

    func updateDraftActualPrice(_ actualPrice: String) {
        draftActualPrice = actualPrice
    }

    func updateDraftNewCategoryName(_ categoryName: String) {
        draftNewCategoryName = categoryName
    }

    func updateSelectedCategoryFilter(_ category: ShoppingItem.Category?) {
        selectedCategoryFilter = category
        refreshSnapshot()
    }

    func updateSortOption(_ sortOption: ShoppingItem.SortOption) {
        self.sortOption = sortOption
        refreshSnapshot()
    }

    func presentCategoryManager() {
        draftNewCategoryName = ""
        selectedCategoryForRename = availableCategories.first
        draftRenamedCategoryName = selectedCategoryForRename?.rawValue ?? ""
        isCategoryManagerPresented = true
    }

    func dismissCategoryManager() {
        isCategoryManagerPresented = false
        selectedCategoryForRename = nil
        draftRenamedCategoryName = ""
        draftNewCategoryName = ""
    }

    func selectCategoryForRename(_ category: ShoppingItem.Category) {
        selectedCategoryForRename = category
        draftRenamedCategoryName = category.rawValue
    }

    func updateDraftRenamedCategoryName(_ categoryName: String) {
        draftRenamedCategoryName = categoryName
    }

    func createCategoryFromDraft() async {
        guard
            let category = normalizedNewCategory,
            let currentList
        else {
            return
        }

        do {
            let updatedList = currentList.addingCategory(category, updatedAt: now())
            try await persist(updatedList)
            draftCategory = category
            selectedCategoryForRename = category
            draftRenamedCategoryName = category.rawValue
            draftNewCategoryName = ""
        } catch {
            dismissEditor()
            state = .failed
        }
    }

    func renameSelectedCategory() async {
        guard
            let selectedCategoryForRename,
            let renamedCategory = normalizedRenamedCategory,
            let currentList
        else {
            return
        }

        do {
            let updatedList = currentList.renamingCategory(
                selectedCategoryForRename,
                to: renamedCategory,
                updatedAt: now()
            )
            try await persist(updatedList)
            if draftCategory.matches(selectedCategoryForRename) {
                draftCategory = renamedCategory
            }
            if self.selectedCategoryFilter?.matches(selectedCategoryForRename) == true {
                self.selectedCategoryFilter = renamedCategory
            }
            self.selectedCategoryForRename = renamedCategory
            draftRenamedCategoryName = renamedCategory.rawValue
        } catch {
            dismissEditor()
            state = .failed
        }
    }

    func saveDraft() async {
        guard
            let editorMode,
            let normalizedDraftName,
            let currentList,
            areDraftPricesValid
        else {
            return
        }

        let plannedPrice = normalizedDraftPlannedPrice
        let actualPrice = normalizedDraftActualPrice
        let category = normalizedDraftCategory

        do {
            let updatedList: ShoppingList

            switch editorMode {
            case .create:
                updatedList = currentList.addingItem(
                    id: makeUUID(),
                    name: normalizedDraftName,
                    quantity: draftQuantity,
                    category: category,
                    storeName: normalizedDraftStoreName,
                    plannedPrice: plannedPrice,
                    actualPrice: actualPrice,
                    updatedAt: now()
                )
            case .edit(let itemID):
                updatedList = try currentList.updatingItem(
                    id: itemID,
                    name: normalizedDraftName,
                    quantity: draftQuantity,
                    category: category,
                    storeName: normalizedDraftStoreName,
                    plannedPrice: plannedPrice,
                    actualPrice: actualPrice,
                    updatedAt: now()
                )
            }

            try await persist(updatedList)
            dismissEditor()
        } catch {
            dismissEditor()
            state = .failed
        }
    }

    func deleteItem(id: UUID) async {
        guard let currentList else {
            return
        }

        do {
            let updatedList = try currentList.deletingItem(id: id, updatedAt: now())
            try await persist(updatedList)
        } catch {
            dismissEditor()
            state = .failed
        }
    }

    func moveItems(fromOffsets: IndexSet, toOffset: Int) async {
        guard let currentList else {
            return
        }

        var reorderedItems = currentList.items.sorted(by: itemSortComparator)
        reorderedItems.move(fromOffsets: fromOffsets, toOffset: toOffset)
        let timestamp = now()
        let updatedList = currentList.replacingItems(
            ShoppingList.reindexedItems(reorderedItems, updatedAt: timestamp),
            updatedAt: timestamp
        )

        do {
            try await persist(updatedList)
        } catch {
            dismissEditor()
            state = .failed
        }
    }

    var canCreateItem: Bool {
        if case .loaded = state {
            return true
        }

        return false
    }

    var canReorderItems: Bool {
        false
    }

    var canEnterShoppingMode: Bool {
        guard case .loaded(let snapshot) = state else {
            return false
        }

        return currentList?.isTemplate == false && snapshot.items.isEmpty == false
    }

    var isDraftSubmissionDisabled: Bool {
        guard
            let normalizedDraftName,
            normalizedDraftName.isEmpty == false,
            areDraftPricesValid
        else {
            return true
        }

        switch editorMode {
        case .create:
            return false
        case .edit(let itemID):
            guard let item = currentList?.items.first(where: { $0.id == itemID }) else {
                return true
            }

            return item.name == normalizedDraftName &&
                item.quantity == draftQuantity &&
                item.category == normalizedDraftCategory &&
                item.storeName == normalizedDraftStoreName &&
                item.plannedPrice == normalizedDraftPlannedPrice &&
                item.actualPrice == normalizedDraftActualPrice
        case .none:
            return true
        }
    }

    var availableCategories: [ShoppingItem.Category] {
        guard let currentList else {
            return ShoppingItem.Category.defaultCategories
        }

        return availableCategories(from: currentList)
    }

    var isCreateCategoryDisabled: Bool {
        guard let normalizedNewCategory else {
            return true
        }

        return availableCategories.contains { $0.matches(normalizedNewCategory) }
    }

    var isRenameCategoryDisabled: Bool {
        guard
            let selectedCategoryForRename,
            let normalizedRenamedCategory
        else {
            return true
        }

        return selectedCategoryForRename.matches(normalizedRenamedCategory)
    }

    var quickEntrySuggestions: [QuickEntrySuggestion] {
        guard case .create = editorMode else {
            return []
        }

        let query = normalizedHistoryKey(from: draftName)
        let baseSuggestions = historySuggestions

        let filteredSuggestions: [QuickEntrySuggestion]
        if query.isEmpty {
            filteredSuggestions = baseSuggestions
        } else {
            filteredSuggestions = baseSuggestions.filter {
                normalizedHistoryKey(from: $0.name).contains(query)
            }
        }

        return filteredSuggestions
            .sorted { lhs, rhs in
                let lhsPrefixMatch = normalizedHistoryKey(from: lhs.name).hasPrefix(query)
                let rhsPrefixMatch = normalizedHistoryKey(from: rhs.name).hasPrefix(query)

                if lhsPrefixMatch != rhsPrefixMatch {
                    return lhsPrefixMatch
                }

                if lhs.usageCount != rhs.usageCount {
                    return lhs.usageCount > rhs.usageCount
                }

                if lhs.lastUsedAt != rhs.lastUsedAt {
                    return lhs.lastUsedAt > rhs.lastUsedAt
                }

                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            .prefix(5)
            .map { $0 }
    }

    var storeSuggestions: [StoreSuggestion] {
        guard editorMode != nil else {
            return []
        }

        let query = normalizedStoreKey(from: draftStoreName)
        let groupedStoreEntries = Dictionary(
            grouping: historyItems.compactMap { item -> (String, String, Date)? in
                guard let storeName = item.storeName else {
                    return nil
                }

                let normalizedStoreName = normalizedStoreKey(from: storeName)
                guard normalizedStoreName.isEmpty == false else {
                    return nil
                }

                return (normalizedStoreName, storeName, item.updatedAt)
            },
            by: \.0
        )
        let baseSuggestions: [StoreSuggestion] = groupedStoreEntries.map { element in
            let normalizedStoreName = element.key
            let entries = element.value
            let mostRecentEntry = entries.max(by: { $0.2 < $1.2 }) ?? entries[0]

            return StoreSuggestion(
                id: normalizedStoreName,
                name: mostRecentEntry.1,
                usageCount: entries.count,
                lastUsedAt: mostRecentEntry.2
            )
        }

        let filteredSuggestions: [StoreSuggestion]
        if query.isEmpty {
            filteredSuggestions = baseSuggestions
        } else {
            filteredSuggestions = baseSuggestions.filter {
                normalizedStoreKey(from: $0.name).contains(query)
            }
        }

        return filteredSuggestions
            .sorted { lhs, rhs in
                let lhsPrefixMatch = normalizedStoreKey(from: lhs.name).hasPrefix(query)
                let rhsPrefixMatch = normalizedStoreKey(from: rhs.name).hasPrefix(query)

                if lhsPrefixMatch != rhsPrefixMatch {
                    return lhsPrefixMatch
                }

                if lhs.usageCount != rhs.usageCount {
                    return lhs.usageCount > rhs.usageCount
                }

                if lhs.lastUsedAt != rhs.lastUsedAt {
                    return lhs.lastUsedAt > rhs.lastUsedAt
                }

                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            .prefix(5)
            .map { $0 }
    }

    var priceMemorySuggestion: PriceMemorySuggestion? {
        guard
            let normalizedDraftHistoryKey,
            let normalizedDraftStoreLookupKey
        else {
            return nil
        }

        let matchingItems = historyItems.filter { item in
            normalizedHistoryKey(from: item.name) == normalizedDraftHistoryKey &&
                normalizedStoreKey(from: item.storeName) == normalizedDraftStoreLookupKey &&
                item.id != currentEditingItemID
        }

        if let actualPriceItem = matchingItems
            .filter({ $0.actualPrice != nil })
            .max(by: { $0.updatedAt < $1.updatedAt }) {
            return PriceMemorySuggestion(
                storeName: actualPriceItem.storeName ?? "",
                price: actualPriceItem.actualPrice ?? .zero,
                kind: .actual,
                lastUsedAt: actualPriceItem.updatedAt
            )
        }

        if let plannedPriceItem = matchingItems
            .filter({ $0.plannedPrice != nil })
            .max(by: { $0.updatedAt < $1.updatedAt }) {
            return PriceMemorySuggestion(
                storeName: plannedPriceItem.storeName ?? "",
                price: plannedPriceItem.plannedPrice ?? .zero,
                kind: .planned,
                lastUsedAt: plannedPriceItem.updatedAt
            )
        }

        return nil
    }

    func applyQuickEntrySuggestion(id: QuickEntrySuggestion.ID) {
        guard let suggestion = quickEntrySuggestions.first(where: { $0.id == id }) else {
            return
        }

        draftName = suggestion.name
        draftQuantity = suggestion.quantity
        draftCategory = suggestion.category
        draftStoreName = suggestion.storeName ?? ""
        draftPlannedPrice = draftString(for: suggestion.plannedPrice)
        draftActualPrice = ""
        draftNewCategoryName = ""
    }

    func applyStoreSuggestion(id: StoreSuggestion.ID) {
        guard let suggestion = storeSuggestions.first(where: { $0.id == id }) else {
            return
        }

        draftStoreName = suggestion.name
    }

    func applyPriceMemorySuggestion() {
        guard let suggestion = priceMemorySuggestion else {
            return
        }

        draftPlannedPrice = draftString(for: suggestion.price)
    }

    private var normalizedDraftName: String? {
        let trimmedName = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? nil : trimmedName
    }

    private var normalizedDraftHistoryKey: String? {
        guard let normalizedDraftName else {
            return nil
        }

        return normalizedHistoryKey(from: normalizedDraftName)
    }

    private var normalizedDraftStoreName: String? {
        let trimmedStoreName = draftStoreName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedStoreName.isEmpty ? nil : trimmedStoreName
    }

    private var normalizedDraftStoreLookupKey: String? {
        guard let normalizedDraftStoreName else {
            return nil
        }

        return normalizedStoreKey(from: normalizedDraftStoreName)
    }

    private var normalizedDraftPlannedPrice: Decimal? {
        normalizedPrice(from: draftPlannedPrice)
    }

    private var normalizedDraftActualPrice: Decimal? {
        normalizedPrice(from: draftActualPrice)
    }

    private var normalizedDraftCategory: ShoppingItem.Category {
        normalizedNewCategory ?? draftCategory
    }

    private var normalizedNewCategory: ShoppingItem.Category? {
        normalizedCategory(from: draftNewCategoryName)
    }

    private var normalizedRenamedCategory: ShoppingItem.Category? {
        normalizedCategory(from: draftRenamedCategoryName)
    }

    private var areDraftPricesValid: Bool {
        isValidPriceDraft(draftPlannedPrice) && isValidPriceDraft(draftActualPrice)
    }

    private var currentEditingItemID: UUID? {
        guard case .edit(let itemID) = editorMode else {
            return nil
        }

        return itemID
    }

    private var suggestedCategoryForNewItem: ShoppingItem.Category {
        guard let currentList else {
            return .produce
        }

        return currentList.items
            .max { lhs, rhs in
                if lhs.createdAt == rhs.createdAt {
                    return lhs.sortOrder < rhs.sortOrder
                }

                return lhs.createdAt < rhs.createdAt
            }
            .map(\.category)
            ?? .produce
    }

    private var historyItems: [ShoppingItem] {
        allLists
            .filter { $0.isTemplate == false }
            .flatMap(\.items)
    }

    private var historySuggestions: [QuickEntrySuggestion] {
        Dictionary(grouping: historyItems, by: { normalizedHistoryKey(from: $0.name) })
            .compactMap { normalizedName, items in
                guard
                    normalizedName.isEmpty == false,
                    let mostRecentItem = items.max(by: { $0.updatedAt < $1.updatedAt })
                else {
                    return nil
                }

                return QuickEntrySuggestion(
                    id: normalizedName,
                    name: mostRecentItem.name,
                    quantity: mostRecentItem.quantity,
                    category: mostRecentItem.category,
                    storeName: mostRecentItem.storeName,
                    plannedPrice: mostRecentItem.plannedPrice,
                    usageCount: items.count,
                    lastUsedAt: mostRecentItem.updatedAt
                )
            }
    }

    private var itemSortComparator: (ShoppingItem, ShoppingItem) -> Bool {
        { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.createdAt < rhs.createdAt
            }

            return lhs.sortOrder < rhs.sortOrder
        }
    }

    private func makeSnapshot(from list: ShoppingList) -> ListSnapshot {
        let visibleItems = filteredItems(from: list)
        let itemRows = sortedItems(visibleItems).map(ItemRow.init)

        return ListSnapshot(
            listID: list.id,
            listName: list.name,
            plannedTotal: list.plannedTotal,
            actualTotal: list.actualTotal,
            budgetDelta: list.budgetDelta,
            actualPricedItemCount: list.actualPricedItemCount,
            items: itemRows,
            itemSections: makeItemSections(from: visibleItems)
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

    private func normalizedCategory(from categoryName: String) -> ShoppingItem.Category? {
        let trimmedCategoryName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedCategoryName.isEmpty == false else {
            return nil
        }

        return ShoppingItem.Category(trimmedCategoryName)
    }

    private func normalizedHistoryKey(from name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).folding(options: [.diacriticInsensitive, .caseInsensitive], locale: locale)
    }

    private func normalizedStoreKey(from storeName: String?) -> String {
        guard let storeName else {
            return ""
        }

        return storeName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: locale)
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
        self.allLists = updatedLists
        currentList = updatedList
        state = .loaded(makeSnapshot(from: updatedList))
    }

    private func replace(
        listID: UUID,
        in lists: [ShoppingList],
        with updatedList: ShoppingList
    ) throws -> [ShoppingList] {
        guard let index = lists.firstIndex(where: { $0.id == listID }) else {
            throw ListDetailViewModelError.listNotFound
        }

        var updatedLists = lists
        updatedLists[index] = updatedList
        return updatedLists
    }
}

private extension ListDetailViewModel.ItemRow {
    init(item: ShoppingItem) {
        id = item.id
        name = item.name
        quantity = item.quantity
        category = item.category
        storeName = item.storeName
        plannedTotal = item.plannedTotal
        actualTotal = item.actualTotal
        isCompleted = item.isCompleted
        updatedAt = item.updatedAt
    }
}

private enum ListDetailViewModelError: Error {
    case listNotFound
}
