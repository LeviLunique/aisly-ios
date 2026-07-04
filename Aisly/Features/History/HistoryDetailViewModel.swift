import Foundation

@MainActor
final class HistoryDetailViewModel: ObservableObject {
    enum ViewState: Equatable {
        case idle
        case loading
        case loaded(PurchaseHistoryEntry)
        case failed
    }

    @Published private(set) var state: ViewState = .idle
    @Published var searchQuery = ""

    private let entryID: UUID
    private let historyRepository: any PurchaseHistoryRepository
    private let listRepository: any ShoppingListRepository
    private let categoryRepository: (any ShoppingCategoryRepository)?
    private let now: @Sendable () -> Date
    private let makeUUID: @Sendable () -> UUID
    private var entries: [PurchaseHistoryEntry] = []
    private var categoryDefinitions: [ShoppingCategoryDefinition] = ShoppingCategoryDefinition.defaultDefinitions

    init(
        entryID: UUID,
        historyRepository: any PurchaseHistoryRepository,
        listRepository: any ShoppingListRepository,
        categoryRepository: (any ShoppingCategoryRepository)? = nil,
        now: @escaping @Sendable () -> Date = { Date() },
        makeUUID: @escaping @Sendable () -> UUID = { UUID() }
    ) {
        self.entryID = entryID
        self.historyRepository = historyRepository
        self.listRepository = listRepository
        self.categoryRepository = categoryRepository
        self.now = now
        self.makeUUID = makeUUID
    }

    var entry: PurchaseHistoryEntry? {
        if case .loaded(let entry) = state {
            return entry
        }

        return nil
    }

    /// Snapshot sections narrowed to purchased items matching the current
    /// search query (diacritic/case-insensitive). Sections that end up empty
    /// are dropped; an empty query returns everything.
    var filteredSections: [PurchaseHistoryEntry.SectionSnapshot] {
        guard let entry else {
            return []
        }

        let query = Self.normalized(searchQuery)

        return entry.sections.compactMap { section in
            let purchasedItems = section.items.filter(\.isPurchased)
            let matchingItems = query.isEmpty
                ? purchasedItems
                : purchasedItems.filter { Self.normalized($0.name).contains(query) }

            guard matchingItems.isEmpty == false else {
                return nil
            }

            return PurchaseHistoryEntry.SectionSnapshot(name: section.name, items: matchingItems)
        }
    }

    func categoryAppearance(forSectionName name: String) -> (iconName: String, colorHex: UInt32) {
        let category = ShoppingItem.Category(name)
        guard let definition = categoryDefinitions.first(where: { $0.category.matches(category) }) else {
            return ("tag", 0x6B7280)
        }

        return (definition.iconName, definition.colorHex)
    }

    func loadIfNeeded() async {
        guard case .idle = state else {
            return
        }

        await load()
    }

    func load() async {
        state = .loading

        if let categoryRepository {
            categoryDefinitions = (try? await categoryRepository.fetchCategories())
                ?? ShoppingCategoryDefinition.defaultDefinitions
        }

        do {
            entries = try await historyRepository.fetchEntries()
            guard let entry = entries.first(where: { $0.id == entryID }) else {
                state = .failed
                return
            }

            state = .loaded(entry)
        } catch {
            state = .failed
        }
    }

    @discardableResult
    func repeatList() async -> Bool {
        guard let entry else {
            return false
        }

        do {
            let activeList = entry.repeatingAsList(
                id: makeUUID(),
                makeItemID: makeUUID,
                finishedAt: now()
            )
            let updatedLists = [activeList] + (try await listRepository.fetchLists())
            try await listRepository.saveLists(updatedLists)
            return true
        } catch {
            state = .failed
            return false
        }
    }

    /// Returns true when the template was persisted, so the view can show
    /// success feedback only for real saves.
    @discardableResult
    func createTemplate() async -> Bool {
        guard let entry else {
            return false
        }

        do {
            let activeList = entry.repeatingAsList(
                id: makeUUID(),
                makeItemID: makeUUID,
                finishedAt: now(),
                useActualPricesAsPlan: true
            )
            let template = activeList.makingTemplate(
                id: makeUUID(),
                name: entry.name,
                recurrence: .weekly,
                makeItemID: makeUUID,
                updatedAt: now()
            )
            let updatedLists = [template] + (try await listRepository.fetchLists())
            try await listRepository.saveLists(updatedLists)
            return true
        } catch {
            state = .failed
            return false
        }
    }

    func deleteHistory() async -> Bool {
        do {
            let updatedEntries = entries.filter { $0.id != entryID }
            try await historyRepository.saveEntries(updatedEntries)
            entries = updatedEntries
            return true
        } catch {
            state = .failed
            return false
        }
    }

    private static func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .autoupdatingCurrent)
    }
}
