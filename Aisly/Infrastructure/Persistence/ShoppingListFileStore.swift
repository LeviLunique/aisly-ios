import Foundation

actor ShoppingListFileStore {
    private let fileURL: URL
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(fileURL: URL) {
        self.fileURL = fileURL

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder
    }

    func load() throws -> [StoredShoppingList] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)

        guard !data.isEmpty else {
            return []
        }

        return try decoder.decode([StoredShoppingList].self, from: data)
    }

    func save(_ lists: [StoredShoppingList]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let data = try encoder.encode(lists)
        try data.write(to: fileURL, options: .atomic)
    }
}

struct StoredShoppingList: Codable, Equatable {
    let id: UUID
    let name: String
    let createdAt: Date
    let updatedAt: Date
    let isArchived: Bool

    init(list: ShoppingList) {
        id = list.id
        name = list.name
        createdAt = list.createdAt
        updatedAt = list.updatedAt
        isArchived = list.isArchived
    }

    var model: ShoppingList {
        ShoppingList(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isArchived: isArchived
        )
    }
}
