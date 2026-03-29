import Combine
import Foundation

@MainActor
final class ListDetailViewModel: ObservableObject {
    struct ItemRow: Identifiable, Equatable {
        let id: UUID
        let name: String
        let quantity: Int
        let category: ShoppingItem.Category
        let updatedAt: Date
    }

    struct ListSnapshot: Equatable {
        let listID: UUID
        let listName: String
        let items: [ItemRow]
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

    private let listID: UUID
    private let repository: any ShoppingListRepository
    private let now: @Sendable () -> Date
    private let makeUUID: @Sendable () -> UUID
    private var currentList: ShoppingList?

    init(
        listID: UUID,
        repository: any ShoppingListRepository,
        now: @escaping @Sendable () -> Date = { Date() },
        makeUUID: @escaping @Sendable () -> UUID = { UUID() }
    ) {
        self.listID = listID
        self.repository = repository
        self.now = now
        self.makeUUID = makeUUID
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

    func presentCreateItem() {
        draftName = ""
        draftQuantity = 1
        draftCategory = .produce
        editorMode = .create
    }

    func presentEditItem(id: UUID) {
        guard let item = currentList?.items.first(where: { $0.id == id }) else {
            return
        }

        draftName = item.name
        draftQuantity = item.quantity
        draftCategory = item.category
        editorMode = .edit(id)
    }

    func dismissEditor() {
        editorMode = nil
        draftName = ""
        draftQuantity = 1
        draftCategory = .produce
    }

    func updateDraftName(_ draftName: String) {
        self.draftName = draftName
    }

    func updateDraftQuantity(_ quantity: Int) {
        draftQuantity = max(1, quantity)
    }

    func updateDraftCategory(_ category: ShoppingItem.Category) {
        draftCategory = category
    }

    func saveDraft() async {
        guard
            let editorMode,
            let normalizedDraftName,
            let currentList
        else {
            return
        }

        do {
            let updatedList: ShoppingList

            switch editorMode {
            case .create:
                updatedList = currentList.addingItem(
                    id: makeUUID(),
                    name: normalizedDraftName,
                    quantity: draftQuantity,
                    category: draftCategory,
                    updatedAt: now()
                )
            case .edit(let itemID):
                updatedList = try currentList.updatingItem(
                    id: itemID,
                    name: normalizedDraftName,
                    quantity: draftQuantity,
                    category: draftCategory,
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
        guard case .loaded(let snapshot) = state else {
            return false
        }

        return snapshot.items.count > 1
    }

    var isDraftSubmissionDisabled: Bool {
        guard
            let normalizedDraftName,
            normalizedDraftName.isEmpty == false
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
                item.category == draftCategory
        case .none:
            return true
        }
    }

    private var normalizedDraftName: String? {
        let trimmedName = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? nil : trimmedName
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
        ListSnapshot(
            listID: list.id,
            listName: list.name,
            items: list.items
                .sorted(by: itemSortComparator)
                .map(ItemRow.init)
        )
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
        updatedAt = item.updatedAt
    }
}

private enum ListDetailViewModelError: Error {
    case listNotFound
}
