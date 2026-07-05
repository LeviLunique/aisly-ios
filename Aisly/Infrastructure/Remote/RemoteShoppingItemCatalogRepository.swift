import Foundation

/// Remote adapter for `ShoppingItemCatalogRepository`. Diffs by entry id:
/// creates POST with the client-generated id, updates PUT, removals DELETE.
final class RemoteShoppingItemCatalogRepository: ShoppingItemCatalogRepository, Sendable {
    private let client: AislyAPIClient
    private let snapshot = RemoteSnapshotBox<[ShoppingItemCatalogEntry]>()

    private static let catalogItemsPath = "/api/v1/catalog/items"

    init(client: AislyAPIClient) {
        self.client = client
    }

    // MARK: - ShoppingItemCatalogRepository

    func fetchEntries() async throws -> [ShoppingItemCatalogEntry] {
        let wireEntries: [RemoteCatalogItemResponse] = try await client.get(
            Self.catalogItemsPath,
            queryItems: [URLQueryItem(name: "includeArchived", value: "true")]
        )

        let mapped = wireEntries.map(Self.mapToDomain)
        await snapshot.set(mapped)
        return mapped
    }

    func saveEntries(_ entries: [ShoppingItemCatalogEntry]) async throws {
        let baseline: [ShoppingItemCatalogEntry]
        if let known = await snapshot.get() {
            baseline = known
        } else {
            baseline = try await fetchEntries()
        }

        let previousByID = Dictionary(baseline.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let currentByID = Dictionary(entries.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        for old in baseline where currentByID[old.id] == nil {
            try await client.delete(Self.catalogItemsPath + "/\(old.id.uuidString)")
        }

        for entry in entries {
            if let old = previousByID[entry.id] {
                if Self.contentChanged(from: old, to: entry) {
                    try await client.put(
                        Self.catalogItemsPath + "/\(entry.id.uuidString)",
                        body: RemoteCatalogItemRequest(entry: entry, includeID: false)
                    )
                }
            } else {
                try await client.post(
                    Self.catalogItemsPath,
                    body: RemoteCatalogItemRequest(entry: entry, includeID: true)
                )
            }
        }

        await snapshot.set(entries)
    }

    // MARK: - Internals

    private static func contentChanged(
        from old: ShoppingItemCatalogEntry,
        to new: ShoppingItemCatalogEntry
    ) -> Bool {
        old.name != new.name
            || old.category.rawValue != new.category.rawValue
            || old.storeName != new.storeName
            || old.plannedPrice != new.plannedPrice
            || old.actualPrice != new.actualPrice
            || old.isArchived != new.isArchived
            || old.isFavorite != new.isFavorite
            || old.quantity != new.quantity
            || old.unit != new.unit
            || old.note != new.note
    }

    private static func mapToDomain(_ wire: RemoteCatalogItemResponse) -> ShoppingItemCatalogEntry {
        let fallbackDate = wire.createdAt ?? Date()

        return ShoppingItemCatalogEntry(
            id: wire.id,
            name: wire.name,
            category: ShoppingItem.Category(wire.categoryName ?? ""),
            storeName: wire.storeName,
            plannedPrice: wire.plannedPrice,
            actualPrice: wire.actualPrice,
            isArchived: wire.archived ?? false,
            createdAt: fallbackDate,
            updatedAt: wire.updatedAt ?? fallbackDate,
            isFavorite: wire.favorite ?? false,
            quantity: wire.quantity ?? 1,
            unit: RemoteMapping.unit(fromServer: wire.unit),
            note: wire.note ?? ""
        )
    }
}
