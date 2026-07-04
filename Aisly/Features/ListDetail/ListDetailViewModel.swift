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
        let unit: ShoppingItem.Unit
        let note: String
        let isFavorite: Bool
        let category: ShoppingItem.Category
        let storeName: String?
        let plannedTotal: Decimal?
        let actualTotal: Decimal?
        let isCompleted: Bool
        let updatedAt: Date
    }

    struct ItemSection: Identifiable, Equatable {
        let id: String
        let title: String
        let iconName: String
        let colorHex: UInt32
        let items: [ItemRow]

        init(
            id: String,
            title: String,
            iconName: String = "tag",
            colorHex: UInt32 = 0x6B7280,
            items: [ItemRow]
        ) {
            self.id = id
            self.title = title
            self.iconName = iconName
            self.colorHex = colorHex
            self.items = items
        }
    }

    struct ListSnapshot: Equatable {
        let listID: UUID
        let listName: String
        let budget: Decimal?
        let plannedTotal: Decimal
        let actualTotal: Decimal
        let budgetDelta: Decimal?
        let planDelta: Decimal?
        let actualPricedItemCount: Int
        let purchasedItemCount: Int
        let missingActualPurchasedItemCount: Int
        let items: [ItemRow]
        let itemSections: [ItemSection]

        init(
            listID: UUID,
            listName: String,
            budget: Decimal? = nil,
            plannedTotal: Decimal,
            actualTotal: Decimal,
            budgetDelta: Decimal?,
            planDelta: Decimal? = nil,
            actualPricedItemCount: Int,
            purchasedItemCount: Int? = nil,
            missingActualPurchasedItemCount: Int = 0,
            items: [ItemRow],
            itemSections: [ItemSection]? = nil
        ) {
            self.listID = listID
            self.listName = listName
            self.budget = budget
            self.plannedTotal = plannedTotal
            self.actualTotal = actualTotal
            self.budgetDelta = budgetDelta
            self.planDelta = planDelta
            self.actualPricedItemCount = actualPricedItemCount
            self.purchasedItemCount = purchasedItemCount ?? items.filter(\.isCompleted).count
            self.missingActualPurchasedItemCount = missingActualPurchasedItemCount
            self.items = items
            self.itemSections = itemSections ?? [
                ItemSection(id: "all", title: String(localized: AppStrings.ListDetail.itemsSectionTitle), items: items)
            ]
        }
    }

    struct FinishSummary: Identifiable, Equatable {
        let id: UUID
        let listName: String
        let purchasedItemCount: Int
        let unpurchasedItemCount: Int
        let missingActualPriceCount: Int
        let plannedTotal: Decimal
        let actualTotal: Decimal
        let budget: Decimal?
        let budgetDelta: Decimal?
        let planDelta: Decimal?
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
    @Published private(set) var draftUnit: ShoppingItem.Unit = .unit
    @Published private(set) var draftNote = ""
    @Published private(set) var draftIsFavorite = false
    @Published private(set) var draftCategory: ShoppingItem.Category = .produce
    @Published private(set) var draftStoreName = ""
    @Published private(set) var draftPlannedPrice = ""
    @Published private(set) var draftActualPrice = ""
    @Published private(set) var finishSummary: FinishSummary?

    let listID: UUID
    private let repository: any ShoppingListRepository
    private let categoryRepository: (any ShoppingCategoryRepository)?
    private let catalogRepository: (any ShoppingItemCatalogRepository)?
    private let historyRepository: (any PurchaseHistoryRepository)?
    private let now: @Sendable () -> Date
    private let makeUUID: @Sendable () -> UUID
    private let locale: Locale
    private var allLists: [ShoppingList] = []
    private var currentList: ShoppingList?
    private var categoryDefinitions: [ShoppingCategoryDefinition] = ShoppingCategoryDefinition.defaultDefinitions

    init(
        listID: UUID,
        repository: any ShoppingListRepository,
        categoryRepository: (any ShoppingCategoryRepository)? = nil,
        catalogRepository: (any ShoppingItemCatalogRepository)? = nil,
        historyRepository: (any PurchaseHistoryRepository)? = nil,
        now: @escaping @Sendable () -> Date = { Date() },
        makeUUID: @escaping @Sendable () -> UUID = { UUID() },
        locale: Locale = .autoupdatingCurrent
    ) {
        self.listID = listID
        self.repository = repository
        self.categoryRepository = categoryRepository
        self.catalogRepository = catalogRepository
        self.historyRepository = historyRepository
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
            if let categoryRepository {
                categoryDefinitions = (try? await categoryRepository.fetchCategories())
                    ?? ShoppingCategoryDefinition.defaultDefinitions
            }
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

    /// Icon + color for a category chip / section, from the stored definitions.
    func categoryAppearance(for category: ShoppingItem.Category) -> (iconName: String, colorHex: UInt32) {
        if let definition = categoryDefinitions.first(where: { $0.category.matches(category) }) {
            return (definition.iconName, definition.colorHex)
        }
        return ("tag", 0x6B7280)
    }

    /// Applies a complete category order (list of category ids) — backs the
    /// dedicated "Reorder Categories" sheet. Persists to the category
    /// repository so the order is consistent everywhere.
    func applyCategoryOrder(_ orderedIDs: [String]) async {
        guard let categoryRepository else {
            return
        }

        var definitions = categoryDefinitions

        // Categories that only exist on items may not have a definition yet;
        // create one so they carry an order slot.
        for id in orderedIDs where definitions.contains(where: { $0.category.id == id }) == false {
            guard let category = availableCategories.first(where: { $0.id == id }) else { continue }
            let appearance = categoryAppearance(for: category)
            definitions.append(
                ShoppingCategoryDefinition(name: category.rawValue, iconName: appearance.iconName, colorHex: appearance.colorHex)
            )
        }

        // Stable sort by the requested order; unknown ids keep their relative
        // position at the end.
        definitions = definitions.enumerated()
            .sorted { lhs, rhs in
                let leftRank = orderedIDs.firstIndex(of: lhs.element.category.id) ?? (orderedIDs.count + lhs.offset)
                let rightRank = orderedIDs.firstIndex(of: rhs.element.category.id) ?? (orderedIDs.count + rhs.offset)
                return leftRank < rightRank
            }
            .map(\.element)

        do {
            try await categoryRepository.saveCategories(definitions)
            categoryDefinitions = definitions
            if let currentList {
                state = .loaded(makeSnapshot(from: currentList))
            }
        } catch {
            state = .failed
        }
    }

    /// Reorders the global category order so `movedCategoryID` sits at the
    /// position of `targetCategoryID`. Backs drag-to-reorder of category
    /// sections/columns in List Detail. Persists to the category repository so
    /// the order is consistent everywhere.
    func moveCategory(_ movedCategoryID: String, aheadOf targetCategoryID: String) async {
        guard let categoryRepository, movedCategoryID != targetCategoryID else {
            return
        }

        var definitions = categoryDefinitions

        // Make sure both categories have a definition (item-only categories may
        // not) so they carry an order slot.
        func ensureDefinition(for id: String) {
            guard definitions.contains(where: { $0.category.id == id }) == false else { return }
            guard let category = availableCategories.first(where: { $0.id == id }) else { return }
            let appearance = categoryAppearance(for: category)
            definitions.append(
                ShoppingCategoryDefinition(name: category.rawValue, iconName: appearance.iconName, colorHex: appearance.colorHex)
            )
        }
        ensureDefinition(for: movedCategoryID)
        ensureDefinition(for: targetCategoryID)

        guard
            let fromIndex = definitions.firstIndex(where: { $0.category.id == movedCategoryID }),
            let targetIndex = definitions.firstIndex(where: { $0.category.id == targetCategoryID })
        else {
            return
        }
        let moved = definitions.remove(at: fromIndex)
        let newTargetIndex = definitions.firstIndex(where: { $0.category.id == targetCategoryID }) ?? definitions.count
        // Dropping onto a column to the right places `moved` after it; onto a
        // column to the left places it before — an intuitive swap either way.
        let insertIndex = fromIndex < targetIndex ? newTargetIndex + 1 : newTargetIndex
        definitions.insert(moved, at: min(insertIndex, definitions.count))

        do {
            try await categoryRepository.saveCategories(definitions)
            categoryDefinitions = definitions
            if let currentList {
                state = .loaded(makeSnapshot(from: currentList))
            }
        } catch {
            state = .failed
        }
    }

    func presentCreateItem() {
        draftName = ""
        draftQuantity = 1
        draftUnit = .unit
        draftNote = ""
        draftIsFavorite = false
        draftCategory = availableCategories.first ?? .produce
        draftStoreName = ""
        draftPlannedPrice = ""
        draftActualPrice = ""
        editorMode = .create
    }

    func presentEditItem(id: UUID) {
        guard let item = currentList?.items.first(where: { $0.id == id }) else {
            return
        }

        draftName = item.name
        draftQuantity = item.quantity
        draftUnit = item.unit
        draftNote = item.note
        draftIsFavorite = item.isFavorite
        draftCategory = item.category
        draftStoreName = item.storeName ?? ""
        draftPlannedPrice = draftString(for: item.plannedPrice)
        draftActualPrice = draftString(for: item.actualPrice)
        editorMode = .edit(id)
    }

    func dismissEditor() {
        editorMode = nil
        draftName = ""
        draftQuantity = 1
        draftCategory = availableCategories.first ?? .produce
        draftStoreName = ""
        draftPlannedPrice = ""
        draftActualPrice = ""
    }

    func updateDraftName(_ draftName: String) {
        self.draftName = draftName
    }

    func updateDraftQuantity(_ quantity: Int) {
        draftQuantity = max(1, quantity)
    }

    func updateDraftUnit(_ unit: ShoppingItem.Unit) {
        draftUnit = unit
    }

    func updateDraftNote(_ note: String) {
        draftNote = note
    }

    func updateDraftIsFavorite(_ value: Bool) {
        draftIsFavorite = value
    }

    func updateDraftCategory(_ category: ShoppingItem.Category) {
        draftCategory = category
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

        do {
            let updatedList: ShoppingList

            switch editorMode {
            case .create:
                updatedList = currentList.addingItem(
                    id: makeUUID(),
                    name: normalizedDraftName,
                    quantity: draftQuantity,
                    unit: draftUnit,
                    note: normalizedDraftNote,
                    isFavorite: draftIsFavorite,
                    category: draftCategory,
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
                    unit: draftUnit,
                    note: normalizedDraftNote,
                    isFavorite: draftIsFavorite,
                    category: draftCategory,
                    storeName: normalizedDraftStoreName,
                    plannedPrice: plannedPrice,
                    actualPrice: actualPrice,
                    updatedAt: now()
                )
            }

            if let catalogRepository {
                try? await upsertCatalogEntry(
                    name: normalizedDraftName,
                    quantity: draftQuantity,
                    category: draftCategory,
                    storeName: normalizedDraftStoreName,
                    plannedPrice: plannedPrice,
                    actualPrice: actualPrice,
                    catalogRepository: catalogRepository
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

    /// Deletes several items at once — backs the List Detail selection bar.
    func deleteItems(ids: Set<UUID>) async {
        guard var updatedList = currentList, ids.isEmpty == false else {
            return
        }

        do {
            for id in ids {
                updatedList = try updatedList.deletingItem(id: id, updatedAt: now())
            }
            try await persist(updatedList)
        } catch {
            state = .failed
        }
    }

    /// Moves several items to a category at once — backs the List Detail
    /// selection bar's "Move to category" action.
    func assignCategory(ids: Set<UUID>, to category: ShoppingItem.Category) async {
        guard var updatedList = currentList, ids.isEmpty == false else {
            return
        }

        do {
            for id in ids {
                guard let item = updatedList.items.first(where: { $0.id == id }) else {
                    continue
                }
                updatedList = try updatedList.updatingItem(
                    id: id,
                    name: item.name,
                    quantity: item.quantity,
                    unit: item.unit,
                    note: item.note,
                    isFavorite: item.isFavorite,
                    category: category,
                    storeName: item.storeName,
                    plannedPrice: item.plannedPrice,
                    actualPrice: item.actualPrice,
                    updatedAt: now()
                )
            }
            try await persist(updatedList)
        } catch {
            state = .failed
        }
    }

    /// Marks several items as purchased at once — backs the List Detail
    /// selection bar's "Purchase" action.
    func markItemsPurchased(ids: Set<UUID>) async {
        guard var updatedList = currentList, ids.isEmpty == false else {
            return
        }

        do {
            for id in ids {
                guard let item = updatedList.items.first(where: { $0.id == id }), item.isCompleted == false else {
                    continue
                }
                updatedList = try updatedList.updatingItemCompletion(
                    id: id,
                    isCompleted: true,
                    updatedAt: now()
                )
            }
            try await persist(updatedList)
        } catch {
            state = .failed
        }
    }

    // MARK: - Inline shopping (folded in from ShoppingMode)

    /// Toggles an item's purchased state directly from the detail list.
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
            state = .failed
        }
    }

    /// Presents the lightweight actual-price editor for a single item while
    /// shopping. Reuses the shared item editor draft state, pre-filling with the
    /// current values so a full edit is still possible.
    func presentActualPriceEditor(id: UUID) {
        presentEditItem(id: id)
    }

    /// Un-checks every purchased item — backs the "Clear" action next to the
    /// "N of M purchased" subtitle in List Detail.
    func clearPurchased() async {
        guard var updatedList = currentList else {
            return
        }

        do {
            for item in updatedList.items where item.isCompleted {
                updatedList = try updatedList.updatingItemCompletion(
                    id: item.id,
                    isCompleted: false,
                    updatedAt: now()
                )
            }
            try await persist(updatedList)
        } catch {
            state = .failed
        }
    }


    // MARK: - List-level actions

    var isTemplate: Bool {
        currentList?.isTemplate ?? false
    }

    var isArchivedList: Bool {
        currentList?.isArchived ?? false
    }

    var listIconName: String {
        currentList?.iconName ?? ShoppingList.defaultIconName
    }

    var listColorHex: UInt32 {
        currentList?.colorHex ?? ShoppingList.defaultColorHex
    }

    var listBudget: Decimal? {
        currentList?.budget
    }

    var listName: String {
        currentList?.name ?? ""
    }

    var canSaveAsTemplate: Bool {
        guard let currentList else {
            return false
        }

        return currentList.isTemplate == false && currentList.isArchived == false
    }

    let availableIconNames = ShoppingList.availableIconNames
    let availableColorHexes = ShoppingList.availableColorHexes

    /// Updates the list's name, budget and appearance (List Info sheet).
    func updateListInfo(
        name: String,
        budget: Decimal?,
        iconName: String,
        colorHex: UInt32
    ) async {
        guard let currentList else {
            return
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.isEmpty == false else {
            return
        }

        let timestamp = now()
        var updatedList = currentList
            .renamed(to: trimmedName, updatedAt: timestamp)
            .updatingAppearance(iconName: iconName, colorHex: colorHex, updatedAt: timestamp)
        updatedList.budget = updatedList.isTemplate ? nil : budget

        do {
            try await persist(updatedList)
        } catch {
            state = .failed
        }
    }

    /// Returns true when the template was persisted, so the view can show
    /// success feedback only for real saves.
    @discardableResult
    func saveAsTemplate(name: String, recurrence: ShoppingList.TemplateRecurrence) async -> Bool {
        guard
            let currentList,
            currentList.isTemplate == false
        else {
            return false
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.isEmpty == false else {
            return false
        }

        do {
            let template = currentList.makingTemplate(
                id: makeUUID(),
                name: trimmedName,
                recurrence: recurrence,
                makeItemID: makeUUID,
                updatedAt: now()
            )
            let existingLists = try await repository.fetchLists()
            let updatedLists = [template] + existingLists.filter { $0.id != template.id }
            try await repository.saveLists(updatedLists)
            allLists = updatedLists
            return true
        } catch {
            state = .failed
            return false
        }
    }

    func archiveList() async {
        guard
            let currentList,
            currentList.isArchived == false
        else {
            return
        }

        do {
            let archived = currentList.archived(updatedAt: now())
            try await persist(archived)
        } catch {
            state = .failed
        }
    }

    func deleteList() async {
        guard let currentList else {
            return
        }

        do {
            let existingLists = try await repository.fetchLists()
            let updatedLists = existingLists.filter { $0.id != currentList.id }
            try await repository.saveLists(updatedLists)
            allLists = updatedLists
        } catch {
            state = .failed
        }
    }

    /// Generates an active list from this template and returns the new list's id.
    @discardableResult
    func generateListFromTemplate() async -> UUID? {
        guard
            let currentList,
            currentList.isTemplate
        else {
            return nil
        }

        do {
            let generated = currentList.generatingListFromTemplate(
                id: makeUUID(),
                makeItemID: makeUUID,
                updatedAt: now()
            )
            let existingLists = try await repository.fetchLists()
            let updatedLists = [generated] + existingLists.filter { $0.id != generated.id }
            try await repository.saveLists(updatedLists)
            allLists = updatedLists
            return generated.id
        } catch {
            state = .failed
            return nil
        }
    }

    func presentFinishPurchase() {
        guard let currentList else {
            return
        }

        finishSummary = FinishSummary(
            id: currentList.id,
            listName: currentList.name,
            purchasedItemCount: currentList.purchasedItemCount,
            unpurchasedItemCount: currentList.items.count - currentList.purchasedItemCount,
            missingActualPriceCount: currentList.missingActualPurchasedItemCount,
            plannedTotal: currentList.plannedTotal,
            actualTotal: currentList.actualTotal,
            budget: currentList.budget,
            budgetDelta: currentList.budgetDelta,
            planDelta: currentList.planDelta
        )
    }

    func dismissFinishSummary() {
        finishSummary = nil
    }

    /// Returns true when the snapshot was saved and the list archived, so the
    /// view can dismiss and show success feedback only for real finishes.
    @discardableResult
    func confirmFinishPurchase() async -> Bool {
        guard
            let currentList,
            let historyRepository
        else {
            return false
        }

        let timestamp = now()
        let historyEntry = PurchaseHistoryEntry.make(
            id: makeUUID(),
            from: currentList,
            finishedAt: timestamp
        )
        let archivedList = currentList.archived(updatedAt: timestamp)

        do {
            async let existingHistory = historyRepository.fetchEntries()
            async let existingLists = repository.fetchLists()
            let updatedHistory = [historyEntry] + (try await existingHistory)
            let updatedLists = try replace(listID: archivedList.id, in: try await existingLists, with: archivedList)

            try await historyRepository.saveEntries(updatedHistory)
            try await repository.saveLists(updatedLists)
            allLists = updatedLists
            self.currentList = archivedList
            finishSummary = nil
            state = .loaded(makeSnapshot(from: archivedList))
            return true
        } catch {
            finishSummary = nil
            state = .failed
            return false
        }
    }

    var canMigrateItemsToTemplate: Bool {
        linkedTemplate != nil
    }

    func migrateItemToTemplate(id: UUID) async {
        guard
            let currentList,
            let template = linkedTemplate,
            let item = currentList.items.first(where: { $0.id == id })
        else {
            return
        }

        let timestamp = now()
        let updatedTemplate = template.addingItem(
            id: makeUUID(),
            name: item.name,
            quantity: item.quantity,
            category: item.category,
            storeName: item.storeName,
            plannedPrice: item.plannedPrice,
            actualPrice: nil,
            updatedAt: timestamp
        )

        do {
            var updatedLists = allLists
            guard let templateIndex = updatedLists.firstIndex(where: { $0.id == updatedTemplate.id }) else {
                return
            }
            updatedLists[templateIndex] = updatedTemplate

            try await repository.saveLists(updatedLists)
            allLists = updatedLists
        } catch {
            state = .failed
        }
    }

    private var linkedTemplate: ShoppingList? {
        guard
            let currentList,
            let templateID = currentList.sourceTemplateID
        else {
            return nil
        }

        return allLists.first { $0.id == templateID && $0.isTemplate }
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
        guard case .loaded(let snapshot) = state else {
            return false
        }

        return snapshot.items.count > 1
    }

    var canFinishPurchase: Bool {
        guard
            historyRepository != nil,
            let currentList,
            currentList.isTemplate == false,
            currentList.isArchived == false
        else {
            return false
        }

        return currentList.items.isEmpty == false
    }

    var availableCategories: [ShoppingItem.Category] {
        ShoppingList.normalizedCategories(
            categoryDefinitions.map(\.category) +
            allLists.flatMap { $0.items.map(\.category) } +
            (currentList?.categories ?? [])
        )
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
                item.category == draftCategory &&
                item.storeName == normalizedDraftStoreName &&
                item.plannedPrice == normalizedDraftPlannedPrice &&
                item.actualPrice == normalizedDraftActualPrice
        case .none:
            return true
        }
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

    private var normalizedDraftNote: String {
        draftNote.trimmingCharacters(in: .whitespacesAndNewlines)
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

    private var areDraftPricesValid: Bool {
        isValidPriceDraft(draftPlannedPrice) && isValidPriceDraft(draftActualPrice)
    }

    private var currentEditingItemID: UUID? {
        guard case .edit(let itemID) = editorMode else {
            return nil
        }

        return itemID
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
        let sortedItems = list.items
            .sorted(by: itemSortComparator)
            .map(ItemRow.init)
        let sections = Dictionary(grouping: sortedItems, by: \.category)
            .map { category, items -> ItemSection in
                let definition = categoryDefinitions.first { $0.category.matches(category) }
                return ItemSection(
                    id: category.id,
                    title: AppStrings.ListDetail.categoryName(for: category, locale: locale),
                    iconName: definition?.iconName ?? "tag",
                    colorHex: definition?.colorHex ?? 0x6B7280,
                    items: items
                )
            }
            .sorted { lhs, rhs in
                let leftIndex = categoryDefinitions.firstIndex { $0.category.id == lhs.id } ?? Int.max
                let rightIndex = categoryDefinitions.firstIndex { $0.category.id == rhs.id } ?? Int.max
                if leftIndex == rightIndex {
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }
                return leftIndex < rightIndex
            }

        return ListSnapshot(
            listID: list.id,
            listName: list.name,
            budget: list.budget,
            plannedTotal: list.plannedTotal,
            actualTotal: list.actualTotal,
            budgetDelta: list.budgetDelta,
            planDelta: list.planDelta,
            actualPricedItemCount: list.actualPricedItemCount,
            purchasedItemCount: list.purchasedItemCount,
            missingActualPurchasedItemCount: list.missingActualPurchasedItemCount,
            items: sortedItems,
            itemSections: sections
        )
    }

    private func upsertCatalogEntry(
        name: String,
        quantity: Int,
        category: ShoppingItem.Category,
        storeName: String?,
        plannedPrice: Decimal?,
        actualPrice: Decimal?,
        catalogRepository: any ShoppingItemCatalogRepository
    ) async throws {
        let timestamp = now()
        var entries = try await catalogRepository.fetchEntries()
        let normalizedKey = ShoppingItemCatalogEntry.normalizedKey(name: name, storeName: storeName)

        if let index = entries.firstIndex(where: { $0.normalizedKey == normalizedKey }) {
            entries[index] = entries[index].updating(
                name: name,
                category: category,
                storeName: storeName,
                plannedPrice: plannedPrice ?? entries[index].plannedPrice,
                actualPrice: actualPrice ?? entries[index].actualPrice,
                updatedAt: timestamp
            )
        } else {
            entries.insert(
                ShoppingItemCatalogEntry.make(
                    id: makeUUID(),
                    name: name,
                    category: category,
                    storeName: storeName,
                    plannedPrice: plannedPrice,
                    actualPrice: actualPrice,
                    now: timestamp
                ),
                at: 0
            )
        }

        try await catalogRepository.saveEntries(entries)
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
        unit = item.unit
        note = item.note
        isFavorite = item.isFavorite
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
