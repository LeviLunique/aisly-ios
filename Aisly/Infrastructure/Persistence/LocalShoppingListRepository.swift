import Foundation

final class LocalShoppingListRepository: ShoppingListRepository {
    private let store: ShoppingListFileStore

    init(store: ShoppingListFileStore) {
        self.store = store
    }

    func fetchLists() async throws -> [ShoppingList] {
        try await store.load().map(\.model)
    }

    func saveLists(_ lists: [ShoppingList]) async throws {
        try await store.save(lists.map(StoredShoppingList.init(list:)))
    }
}
