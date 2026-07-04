import Foundation

enum AppStoragePaths {
    static let appGroupIdentifier = ["group", "com", "levilunique", "aisly"].joined(separator: ".")

    static func persistentDataDirectory(
        fileManager: FileManager = .default,
        sharedContainerURL: URL? = nil
    ) -> URL {
        if let sharedContainerURL {
            return sharedContainerURL
                .appendingPathComponent("Application Support", isDirectory: true)
                .appendingPathComponent("Aisly", isDirectory: true)
        }

        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory

        return baseURL.appendingPathComponent("Aisly", isDirectory: true)
    }

    static func shoppingListsFileURL(
        fileManager: FileManager = .default,
        sharedContainerURL: URL? = nil
    ) -> URL {
        persistentDataDirectory(
            fileManager: fileManager,
            sharedContainerURL: sharedContainerURL
        )
            .appendingPathComponent("shopping-lists.json", isDirectory: false)
    }

    static func shoppingCategoriesFileURL(
        fileManager: FileManager = .default,
        sharedContainerURL: URL? = nil
    ) -> URL {
        persistentDataDirectory(
            fileManager: fileManager,
            sharedContainerURL: sharedContainerURL
        )
            .appendingPathComponent("shopping-categories.json", isDirectory: false)
    }

    static func shoppingItemCatalogFileURL(
        fileManager: FileManager = .default,
        sharedContainerURL: URL? = nil
    ) -> URL {
        persistentDataDirectory(
            fileManager: fileManager,
            sharedContainerURL: sharedContainerURL
        )
            .appendingPathComponent("shopping-item-catalog.json", isDirectory: false)
    }

    static func purchaseHistoryFileURL(
        fileManager: FileManager = .default,
        sharedContainerURL: URL? = nil
    ) -> URL {
        persistentDataDirectory(
            fileManager: fileManager,
            sharedContainerURL: sharedContainerURL
        )
            .appendingPathComponent("purchase-history.json", isDirectory: false)
    }
}
