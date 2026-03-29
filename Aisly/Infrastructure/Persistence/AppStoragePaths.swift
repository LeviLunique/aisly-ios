import Foundation

enum AppStoragePaths {
    static func persistentDataDirectory(fileManager: FileManager = .default) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory

        return baseURL.appendingPathComponent("Aisly", isDirectory: true)
    }

    static func shoppingListsFileURL(fileManager: FileManager = .default) -> URL {
        persistentDataDirectory(fileManager: fileManager)
            .appendingPathComponent("shopping-lists.json", isDirectory: false)
    }
}
