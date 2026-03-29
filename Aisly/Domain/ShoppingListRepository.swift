import Foundation

protocol ShoppingListRepository: Sendable {
    func fetchLists() async throws -> [ShoppingList]
    func saveLists(_ lists: [ShoppingList]) async throws
}
