import Combine
import Foundation

@MainActor
final class ArchivedViewModel: ObservableObject {
    struct ArchivedRow: Identifiable, Equatable {
        let id: UUID
        let name: String
        let updatedAt: Date
        let iconName: String
        let colorHex: UInt32
        let itemCount: Int
        let plannedTotal: Decimal
        let actualTotal: Decimal
        let budget: Decimal?
        let budgetDelta: Decimal?

        init(list: ShoppingList) {
            id = list.id
            name = list.name
            updatedAt = list.updatedAt
            iconName = list.iconName
            colorHex = list.colorHex
            itemCount = list.items.count
            plannedTotal = list.plannedTotal
            actualTotal = list.actualTotal
            budget = list.budget
            budgetDelta = list.budgetDelta
        }
    }

    enum ViewState: Equatable {
        case idle
        case loading
        case loaded([ArchivedRow])
        case failed
    }

    @Published private(set) var state: ViewState = .idle
    @Published var pendingDeletionID: UUID?

    private let repository: any ShoppingListRepository
    private let now: @Sendable () -> Date
    private var lists: [ShoppingList] = []

    init(
        repository: any ShoppingListRepository,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.repository = repository
        self.now = now
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
            let loadedLists = try await repository.fetchLists()
            lists = loadedLists
            state = .loaded(makeRows(from: loadedLists))
        } catch {
            state = .failed
        }
    }

    func unarchiveList(id: UUID) async {
        guard
            let index = lists.firstIndex(where: { $0.id == id }),
            lists[index].isArchived
        else {
            return
        }

        var updatedLists = lists
        updatedLists[index] = updatedLists[index].unarchived(updatedAt: now())

        do {
            try await repository.saveLists(updatedLists)
            lists = updatedLists
            state = .loaded(makeRows(from: updatedLists))
        } catch {
            state = .failed
        }
    }

    func requestDeletion(id: UUID) {
        pendingDeletionID = id
    }

    func cancelDeletion() {
        pendingDeletionID = nil
    }

    func confirmDeletion() async {
        guard let id = pendingDeletionID else {
            return
        }

        pendingDeletionID = nil
        let updatedLists = lists.filter { $0.id != id }

        guard updatedLists.count != lists.count else {
            return
        }

        do {
            try await repository.saveLists(updatedLists)
            lists = updatedLists
            state = .loaded(makeRows(from: updatedLists))
        } catch {
            state = .failed
        }
    }

    var pendingDeletionName: String? {
        guard let pendingDeletionID else {
            return nil
        }

        return lists.first(where: { $0.id == pendingDeletionID })?.name
    }

    private func makeRows(from lists: [ShoppingList]) -> [ArchivedRow] {
        lists
            .filter { $0.isArchived && !$0.isTemplate }
            .sorted(by: listSortComparator)
            .map(ArchivedRow.init)
    }

    private var listSortComparator: (ShoppingList, ShoppingList) -> Bool {
        { lhs, rhs in
            if lhs.updatedAt == rhs.updatedAt {
                return lhs.createdAt > rhs.createdAt
            }

            return lhs.updatedAt > rhs.updatedAt
        }
    }
}
