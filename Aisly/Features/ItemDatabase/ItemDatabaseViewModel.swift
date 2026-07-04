import Combine
import Foundation

@MainActor
final class ItemDatabaseViewModel: ObservableObject {
    enum Scope: String, CaseIterable, Identifiable {
        case all
        case active
        case archived

        var id: String { rawValue }
    }

    enum SortOption: String, CaseIterable, Identifiable {
        case manual = "Manual"
        case name = "Name"
        case mostUsed = "Most used"
        case highestPrice = "Highest price"
        case lowestPrice = "Lowest price"

        var id: String { rawValue }
    }

    enum ViewState: Equatable {
        case idle
        case loading
        case loaded
        case failed
    }

    struct ItemRow: Identifiable, Equatable {
        let id: UUID
        let name: String
        let category: ShoppingItem.Category
        let usageCount: Int
        let storeName: String?
        let plannedPrice: Decimal?
        let actualPrice: Decimal?
        let isArchived: Bool
        let isFavorite: Bool
    }

    struct PendingDeletion: Identifiable, Equatable {
        let id: UUID
        let name: String
    }

    @Published private(set) var state: ViewState = .idle
    @Published var scope: Scope = .all
    @Published var searchQuery: String = ""
    @Published var sortOption: SortOption = .manual
    @Published var categoryFilter: ShoppingItem.Category?
    @Published var isAddSheetPresented = false
    @Published private(set) var pendingDeletion: PendingDeletion?
    @Published private(set) var editingItemID: UUID?

    @Published var draftName = ""
    @Published var draftCategory: ShoppingItem.Category = .produce
    @Published var draftPlannedPrice = ""
    @Published var draftActualPrice = ""
    @Published var draftIsFavorite = false
    @Published var draftQuantity = 1
    @Published var draftUnit: ShoppingItem.Unit = .unit
    @Published var draftNote = ""

    let locale: Locale
    private let catalogRepository: any ShoppingItemCatalogRepository
    private let listRepository: any ShoppingListRepository
    private let categoryRepository: (any ShoppingCategoryRepository)?
    private let now: @Sendable () -> Date
    private let makeUUID: @Sendable () -> UUID

    private var catalogEntries: [ShoppingItemCatalogEntry] = []
    private var allLists: [ShoppingList] = []
    private var categoryDefinitions: [ShoppingCategoryDefinition] = ShoppingCategoryDefinition.defaultDefinitions

    init(
        catalogRepository: any ShoppingItemCatalogRepository,
        listRepository: any ShoppingListRepository,
        categoryRepository: (any ShoppingCategoryRepository)? = nil,
        now: @escaping @Sendable () -> Date = { Date() },
        makeUUID: @escaping @Sendable () -> UUID = { UUID() },
        locale: Locale = .autoupdatingCurrent
    ) {
        self.catalogRepository = catalogRepository
        self.listRepository = listRepository
        self.categoryRepository = categoryRepository
        self.now = now
        self.makeUUID = makeUUID
        self.locale = locale
    }

    // MARK: - Loading

    func loadIfNeeded() async {
        guard case .idle = state else {
            return
        }

        await load()
    }

    func load() async {
        state = .loading

        do {
            async let catalog = try catalogRepository.fetchEntries()
            async let lists = try listRepository.fetchLists()
            let loadedCatalog = try await catalog
            let loadedLists = try await lists

            if let categoryRepository {
                categoryDefinitions = (try? await categoryRepository.fetchCategories())
                    ?? ShoppingCategoryDefinition.defaultDefinitions
            }

            allLists = loadedLists
            catalogEntries = mergeCatalogWithReferencedItems(
                catalog: loadedCatalog,
                lists: loadedLists,
                timestamp: now()
            )

            if catalogEntries.count != loadedCatalog.count {
                try? await catalogRepository.saveEntries(catalogEntries)
            }

            state = .loaded
        } catch {
            state = .failed
        }
    }

    // MARK: - Derived state

    var canCreateItem: Bool {
        if case .loaded = state {
            return true
        }

        return false
    }

    var hasAnyEntry: Bool {
        catalogEntries.isEmpty == false
    }

    var availableCategories: [ShoppingItem.Category] {
        let referencedCategories = catalogEntries.map(\.category) + allLists.flatMap { list in
            list.categories + list.items.map(\.category)
        }
        return ShoppingList.normalizedCategories(
            categoryDefinitions.map(\.category) + referencedCategories
        )
    }

    var rows: [ItemRow] {
        var filtered = filteredEntries()

        if let categoryFilter {
            filtered = filtered.filter { $0.category.matches(categoryFilter) }
        }

        let sorted: [ShoppingItemCatalogEntry]
        switch sortOption {
        case .manual:
            sorted = filtered
        case .name:
            sorted = filtered.sorted { lhs, rhs in
                lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        case .mostUsed:
            sorted = filtered.sorted { usageCount(for: $0) > usageCount(for: $1) }
        case .highestPrice:
            sorted = filtered.sorted { priceValue(for: $0) > priceValue(for: $1) }
        case .lowestPrice:
            sorted = filtered.sorted { priceValue(for: $0) < priceValue(for: $1) }
        }

        return sorted.map(makeRow(from:))
    }

    /// Icon + color for a category chip, from the stored definitions.
    func categoryAppearance(for category: ShoppingItem.Category) -> (iconName: String, colorHex: UInt32) {
        if let definition = categoryDefinitions.first(where: { $0.category.matches(category) }) {
            return (definition.iconName, definition.colorHex)
        }
        return ("tag", 0x6B7280)
    }

    // MARK: - Add / Edit item

    func presentAddItem() {
        editingItemID = nil
        draftName = ""
        draftCategory = availableCategories.first ?? .produce
        draftPlannedPrice = ""
        draftActualPrice = ""
        draftIsFavorite = false
        draftQuantity = 1
        draftUnit = .unit
        draftNote = ""
        isAddSheetPresented = true
    }

    func presentEditItem(id: UUID) {
        guard let entry = catalogEntries.first(where: { $0.id == id }) else {
            return
        }

        editingItemID = entry.id
        draftName = entry.name
        draftCategory = entry.category
        draftPlannedPrice = draftString(for: entry.plannedPrice)
        draftActualPrice = draftString(for: entry.actualPrice)
        draftIsFavorite = entry.isFavorite
        draftQuantity = entry.quantity
        draftUnit = entry.unit
        draftNote = entry.note
        isAddSheetPresented = true
    }

    func dismissAddItem() {
        editingItemID = nil
        isAddSheetPresented = false
    }

    var isAddSubmissionDisabled: Bool {
        normalizedDraftName == nil
            || isValidPriceDraft(draftPlannedPrice) == false
            || isValidPriceDraft(draftActualPrice) == false
    }

    func saveNewItem() async {
        await saveDraft()
    }

    func saveDraft() async {
        guard
            let normalizedName = normalizedDraftName,
            isValidPriceDraft(draftPlannedPrice),
            isValidPriceDraft(draftActualPrice)
        else {
            return
        }

        let timestamp = now()
        let updatedEntries: [ShoppingItemCatalogEntry]

        if let editingItemID, let index = catalogEntries.firstIndex(where: { $0.id == editingItemID }) {
            var entries = catalogEntries
            let entry = entries[index]
            entries[index] = entry.updating(
                name: normalizedName,
                category: draftCategory,
                storeName: entry.storeName,
                plannedPrice: normalizedPrice(from: draftPlannedPrice),
                actualPrice: normalizedPrice(from: draftActualPrice),
                isArchived: entry.isArchived,
                isFavorite: draftIsFavorite,
                quantity: draftQuantity,
                unit: draftUnit,
                note: draftNote.trimmingCharacters(in: .whitespacesAndNewlines),
                updatedAt: timestamp
            )
            updatedEntries = entries
        } else {
            let newEntry = ShoppingItemCatalogEntry.make(
                id: makeUUID(),
                name: normalizedName,
                category: draftCategory,
                storeName: nil,
                plannedPrice: normalizedPrice(from: draftPlannedPrice),
                actualPrice: normalizedPrice(from: draftActualPrice),
                isFavorite: draftIsFavorite,
                quantity: draftQuantity,
                unit: draftUnit,
                note: draftNote.trimmingCharacters(in: .whitespacesAndNewlines),
                now: timestamp
            )
            updatedEntries = [newEntry] + catalogEntries
        }

        do {
            try await catalogRepository.saveEntries(updatedEntries)
            catalogEntries = updatedEntries
            editingItemID = nil
            isAddSheetPresented = false
            state = .loaded
        } catch {
            editingItemID = nil
            isAddSheetPresented = false
            state = .failed
        }
    }

    // MARK: - Archive / Delete

    func archiveItem(id: UUID) async {
        await updateArchivedState(id: id, isArchived: true)
    }

    func unarchiveItem(id: UUID) async {
        await updateArchivedState(id: id, isArchived: false)
    }

    func archiveItems(ids: Set<UUID>) async {
        guard ids.isEmpty == false else {
            return
        }

        let timestamp = now()
        var updatedEntries = catalogEntries
        for index in updatedEntries.indices where ids.contains(updatedEntries[index].id) {
            let entry = updatedEntries[index]
            updatedEntries[index] = entry.updating(
                name: entry.name,
                category: entry.category,
                storeName: entry.storeName,
                plannedPrice: entry.plannedPrice,
                actualPrice: entry.actualPrice,
                isArchived: true,
                updatedAt: timestamp
            )
        }

        do {
            try await catalogRepository.saveEntries(updatedEntries)
            catalogEntries = updatedEntries
            state = .loaded
        } catch {
            state = .failed
        }
    }

    func deleteItems(ids: Set<UUID>) async {
        guard ids.isEmpty == false else {
            return
        }

        do {
            let updatedEntries = catalogEntries.filter { ids.contains($0.id) == false }
            try await catalogRepository.saveEntries(updatedEntries)
            catalogEntries = updatedEntries
            state = .loaded
        } catch {
            state = .failed
        }
    }

    func presentDeleteConfirmation(id: UUID) {
        guard let entry = catalogEntries.first(where: { $0.id == id }) else {
            return
        }

        pendingDeletion = PendingDeletion(id: entry.id, name: entry.name)
    }

    func dismissDeleteConfirmation() {
        pendingDeletion = nil
    }

    func confirmDeletePendingItem() async {
        guard let pendingDeletion else {
            return
        }

        do {
            let updatedEntries = catalogEntries.filter { $0.id != pendingDeletion.id }
            try await catalogRepository.saveEntries(updatedEntries)
            catalogEntries = updatedEntries
            self.pendingDeletion = nil
            state = .loaded
        } catch {
            self.pendingDeletion = nil
            state = .failed
        }
    }

    // MARK: - Private

    private var normalizedDraftName: String? {
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func filteredEntries() -> [ShoppingItemCatalogEntry] {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedQuery = trimmedQuery
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: locale)

        return catalogEntries.filter { entry in
            switch scope {
            case .all:
                break
            case .active where entry.isArchived:
                return false
            case .archived where entry.isArchived == false:
                return false
            case .active, .archived:
                break
            }

            if normalizedQuery.isEmpty == false {
                let normalizedName = entry.name
                    .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: locale)
                if normalizedName.contains(normalizedQuery) == false {
                    return false
                }
            }

            return true
        }
    }

    private func usageCount(for entry: ShoppingItemCatalogEntry) -> Int {
        allLists.reduce(into: 0) { count, list in
            let referenced = list.items.contains { item in
                ShoppingItemCatalogEntry.normalizedKey(
                    name: item.name,
                    storeName: item.storeName
                ) == entry.normalizedKey
            }

            if referenced {
                count += 1
            }
        }
    }

    private func makeRow(from entry: ShoppingItemCatalogEntry) -> ItemRow {
        ItemRow(
            id: entry.id,
            name: entry.name,
            category: entry.category,
            usageCount: usageCount(for: entry),
            storeName: entry.storeName,
            plannedPrice: entry.plannedPrice,
            actualPrice: entry.actualPrice,
            isArchived: entry.isArchived,
            isFavorite: entry.isFavorite
        )
    }

    private func priceValue(for entry: ShoppingItemCatalogEntry) -> Decimal {
        entry.actualPrice ?? entry.plannedPrice ?? 0
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

    private func mergeCatalogWithReferencedItems(
        catalog: [ShoppingItemCatalogEntry],
        lists: [ShoppingList],
        timestamp: Date
    ) -> [ShoppingItemCatalogEntry] {
        var merged = catalog
        var keys = Set(catalog.map(\.normalizedKey))

        for list in lists {
            for item in list.items {
                let key = ShoppingItemCatalogEntry.normalizedKey(
                    name: item.name,
                    storeName: item.storeName
                )

                guard keys.contains(key) == false else {
                    continue
                }

                let entry = ShoppingItemCatalogEntry(
                    id: makeUUID(),
                    name: item.name,
                    category: item.category,
                    storeName: item.storeName,
                    plannedPrice: item.plannedPrice,
                    actualPrice: item.actualPrice,
                    isArchived: false,
                    createdAt: item.createdAt,
                    updatedAt: timestamp,
                    isFavorite: item.isFavorite,
                    quantity: item.quantity,
                    unit: item.unit,
                    note: item.note
                )
                merged.append(entry)
                keys.insert(key)
            }
        }

        return merged
    }

    private func isValidPriceDraft(_ priceDraft: String) -> Bool {
        let trimmed = priceDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || normalizedPrice(from: trimmed) != nil
    }

    private func normalizedPrice(from priceDraft: String) -> Decimal? {
        let trimmed = priceDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            return nil
        }

        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.generatesDecimalNumbers = true

        let candidates = [
            trimmed,
            trimmed.replacingOccurrences(of: ",", with: "."),
            trimmed.replacingOccurrences(of: ".", with: locale.decimalSeparator ?? ".")
        ]

        for candidate in candidates {
            guard let number = formatter.number(from: candidate) else {
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

    private func updateArchivedState(id: UUID, isArchived: Bool) async {
        guard let index = catalogEntries.firstIndex(where: { $0.id == id }) else {
            return
        }

        do {
            var updatedEntries = catalogEntries
            let entry = updatedEntries[index]
            updatedEntries[index] = entry.updating(
                name: entry.name,
                category: entry.category,
                storeName: entry.storeName,
                plannedPrice: entry.plannedPrice,
                actualPrice: entry.actualPrice,
                isArchived: isArchived,
                updatedAt: now()
            )
            try await catalogRepository.saveEntries(updatedEntries)
            catalogEntries = updatedEntries
            state = .loaded
        } catch {
            state = .failed
        }
    }
}
