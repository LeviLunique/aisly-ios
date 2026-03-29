import Foundation

enum AppleSurfaceListStore {
    static func fetchActiveLists(
        fileManager: FileManager = .default
    ) async throws -> [ShoppingList] {
        try await makeRepository(fileManager: fileManager)
            .fetchLists()
            .filter { $0.isArchived == false && $0.isTemplate == false }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    static func fetchActiveList(
        id: UUID,
        fileManager: FileManager = .default
    ) async throws -> ShoppingList? {
        try await fetchActiveLists(fileManager: fileManager)
            .first(where: { $0.id == id })
    }

    private static func makeRepository(
        fileManager: FileManager
    ) -> any ShoppingListRepository {
        LocalShoppingListRepository(
            store: ShoppingListFileStore(
                fileURL: AppStoragePaths.shoppingListsFileURL(fileManager: fileManager)
            )
        )
    }
}
