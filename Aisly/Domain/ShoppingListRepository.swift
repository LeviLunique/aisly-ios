import Foundation

protocol ShoppingListRepository: Sendable {
    func fetchLists() async throws -> [ShoppingList]
    func saveLists(_ lists: [ShoppingList]) async throws
}

protocol ShoppingCategoryRepository: Sendable {
    func fetchCategories() async throws -> [ShoppingCategoryDefinition]
    func saveCategories(_ categories: [ShoppingCategoryDefinition]) async throws
}

protocol ShoppingItemCatalogRepository: Sendable {
    func fetchEntries() async throws -> [ShoppingItemCatalogEntry]
    func saveEntries(_ entries: [ShoppingItemCatalogEntry]) async throws
}

protocol PurchaseHistoryRepository: Sendable {
    func fetchEntries() async throws -> [PurchaseHistoryEntry]
    func saveEntries(_ entries: [PurchaseHistoryEntry]) async throws
}
