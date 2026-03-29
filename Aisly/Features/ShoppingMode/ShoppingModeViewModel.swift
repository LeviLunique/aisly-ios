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
        let sortedItems = list.items.sorted(by: itemSortComparator)
        let remainingItems = sortedItems.filter { $0.isCompleted == false }.map(ItemRow.init)
        let completedItems = sortedItems.filter(\.isCompleted).map(ItemRow.init)

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
            completedItems: completedItems
        )
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
