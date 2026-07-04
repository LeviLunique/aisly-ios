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

final class LocalShoppingItemCatalogRepository: ShoppingItemCatalogRepository {
    private let store: ShoppingItemCatalogFileStore

    init(store: ShoppingItemCatalogFileStore) {
        self.store = store
    }

    func fetchEntries() async throws -> [ShoppingItemCatalogEntry] {
        try await store.load()
    }

    func saveEntries(_ entries: [ShoppingItemCatalogEntry]) async throws {
        try await store.save(entries)
    }
}

final class LocalShoppingCategoryRepository: ShoppingCategoryRepository {
    private let store: ShoppingCategoryFileStore

    init(store: ShoppingCategoryFileStore) {
        self.store = store
    }

    func fetchCategories() async throws -> [ShoppingCategoryDefinition] {
        try await store.load()
    }

    func saveCategories(_ categories: [ShoppingCategoryDefinition]) async throws {
        try await store.save(categories)
    }
}

final class LocalPurchaseHistoryRepository: PurchaseHistoryRepository {
    private let store: PurchaseHistoryFileStore

    init(store: PurchaseHistoryFileStore) {
        self.store = store
    }

    func fetchEntries() async throws -> [PurchaseHistoryEntry] {
        try await store.load()
    }

    func saveEntries(_ entries: [PurchaseHistoryEntry]) async throws {
        try await store.save(entries)
    }
}
