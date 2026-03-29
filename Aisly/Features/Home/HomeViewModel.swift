import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    struct ListSnapshot: Equatable {
        let activeCount: Int
        let archivedCount: Int
    }

    enum ViewState: Equatable {
        case idle
        case loading
        case loaded(ListSnapshot)
        case failed
    }

    @Published private(set) var state: ViewState = .idle

    private let repository: any ShoppingListRepository

    init(repository: any ShoppingListRepository) {
        self.repository = repository
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
            state = .loaded(makeSnapshot(from: lists))
        } catch {
            state = .failed
        }
    }

    private func makeSnapshot(from lists: [ShoppingList]) -> ListSnapshot {
        ListSnapshot(
            activeCount: lists.filter { !$0.isArchived }.count,
            archivedCount: lists.filter(\.isArchived).count
        )
    }
}
