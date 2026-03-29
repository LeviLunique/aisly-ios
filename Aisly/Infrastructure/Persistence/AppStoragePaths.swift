import Foundation

enum AppStoragePaths {
    static let appGroupIdentifier = "group.com.levilunique.aisly"

    static func persistentDataDirectory(
        fileManager: FileManager = .default,
        sharedContainerURL: URL? = nil
    ) -> URL {
        if let sharedContainerURL = sharedContainerURL ?? fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) {
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
}
