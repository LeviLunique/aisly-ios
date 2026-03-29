import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    struct ListRow: Identifiable, Equatable {
        let id: UUID
        let name: String
        let updatedAt: Date
    }

    struct ListSnapshot: Equatable {
        let activeLists: [ListRow]
        let archivedLists: [ListRow]
    }

    enum EditorMode: Equatable, Identifiable {
        case create
        case rename(UUID)

        var id: String {
            switch self {
            case .create:
                return "create"
            case .rename(let id):
                return "rename-\(id.uuidString)"
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

    private let repository: any ShoppingListRepository
    private let now: @Sendable () -> Date
    private let makeUUID: @Sendable () -> UUID
    private var lists: [ShoppingList] = []

    init(
        repository: any ShoppingListRepository,
        now: @escaping @Sendable () -> Date = { Date() },
        makeUUID: @escaping @Sendable () -> UUID = { UUID() }
    ) {
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
            let loadedLists = try await repository.fetchLists()
            lists = loadedLists
            state = .loaded(makeSnapshot(from: loadedLists))
        } catch {
            state = .failed
        }
    }

    func presentCreateList() {
        draftName = ""
        editorMode = .create
    }

    func presentRenameList(id: UUID) {
        guard let list = lists.first(where: { $0.id == id }) else {
            return
        }

        draftName = list.name
        editorMode = .rename(id)
    }

    func dismissEditor() {
        editorMode = nil
        draftName = ""
    }

    func updateDraftName(_ draftName: String) {
        self.draftName = draftName
    }

    func saveDraft() async {
        guard
            let editorMode,
            let normalizedName = normalizedDraftName
        else {
            return
        }

        do {
            let updatedLists: [ShoppingList]

            switch editorMode {
            case .create:
                updatedLists = [
                    ShoppingList.make(
                        id: makeUUID(),
                        name: normalizedName,
                        now: now()
                    )
                ] + lists

            case .rename(let listID):
                updatedLists = try renameList(id: listID, to: normalizedName)
            }

            try await repository.saveLists(updatedLists)
            lists = updatedLists
            state = .loaded(makeSnapshot(from: updatedLists))
            dismissEditor()
        } catch {
            dismissEditor()
            state = .failed
        }
    }

    func archiveList(id: UUID) async {
        do {
            let updatedLists = try archiveListLocally(id: id)
            try await repository.saveLists(updatedLists)
            lists = updatedLists
            state = .loaded(makeSnapshot(from: updatedLists))
        } catch {
            dismissEditor()
            state = .failed
        }
    }

    var isDraftSubmissionDisabled: Bool {
        guard let normalizedDraftName else {
            return true
        }

        switch editorMode {
        case .create:
            return normalizedDraftName.isEmpty
        case .rename(let id):
            guard let existingList = lists.first(where: { $0.id == id }) else {
                return true
            }

            return existingList.name == normalizedDraftName
        case .none:
            return true
        }
    }

    var canCreateList: Bool {
        if case .loaded = state {
            return true
        }

        return false
    }

    private func makeSnapshot(from lists: [ShoppingList]) -> ListSnapshot {
        let activeLists = lists
            .filter { !$0.isArchived }
            .sorted(by: listSortComparator)
            .map(ListRow.init)
        let archivedLists = lists
            .filter(\.isArchived)
            .sorted(by: listSortComparator)
            .map(ListRow.init)

        return ListSnapshot(
            activeLists: activeLists,
            archivedLists: archivedLists
        )
    }

    private var normalizedDraftName: String? {
        let trimmedName = draftName.trimmingCharacters(in: .whitespacesAndNewlines)

        return trimmedName.isEmpty ? nil : trimmedName
    }

    private var listSortComparator: (ShoppingList, ShoppingList) -> Bool {
        { lhs, rhs in
            if lhs.updatedAt == rhs.updatedAt {
                return lhs.createdAt > rhs.createdAt
            }

            return lhs.updatedAt > rhs.updatedAt
        }
    }

    private func renameList(id: UUID, to name: String) throws -> [ShoppingList] {
        guard let index = lists.firstIndex(where: { $0.id == id }) else {
            throw HomeViewModelError.listNotFound
        }

        var updatedLists = lists
        updatedLists[index] = updatedLists[index].renamed(to: name, updatedAt: now())
        return updatedLists
    }

    private func archiveListLocally(id: UUID) throws -> [ShoppingList] {
        guard let index = lists.firstIndex(where: { $0.id == id }) else {
            throw HomeViewModelError.listNotFound
        }

        guard updatedListNeedsArchiving(lists[index]) else {
            return lists
        }

        var updatedLists = lists
        updatedLists[index] = updatedLists[index].archived(updatedAt: now())
        return updatedLists
    }

    private func updatedListNeedsArchiving(_ list: ShoppingList) -> Bool {
        list.isArchived == false
    }
}

private extension HomeViewModel.ListRow {
    init(list: ShoppingList) {
        id = list.id
        name = list.name
        updatedAt = list.updatedAt
    }
}

private enum HomeViewModelError: Error {
    case listNotFound
}
