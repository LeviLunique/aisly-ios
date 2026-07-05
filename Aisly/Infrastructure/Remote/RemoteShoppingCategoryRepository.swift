import Foundation

/// Remote adapter for `ShoppingCategoryRepository`. The iOS domain keys
/// categories by name while the server keys them by UUID, so the adapter
/// keeps a name→UUID map from the last fetch and diffs by normalized name.
final class RemoteShoppingCategoryRepository: ShoppingCategoryRepository, Sendable {
    struct Snapshot: Sendable {
        var definitions: [ShoppingCategoryDefinition]
        /// Normalized category name → server UUID.
        var serverIDs: [String: UUID]
        /// Normalized names of server-fixed categories (e.g. "Others") that
        /// must never be deleted.
        var fixedNames: Set<String>
        /// Server ordering, used to detect reorders.
        var orderedIDs: [UUID]
    }

    private let client: AislyAPIClient
    private let snapshot = RemoteSnapshotBox<Snapshot>()

    private static let categoriesPath = "/api/v1/categories"

    init(client: AislyAPIClient) {
        self.client = client
    }

    // MARK: - ShoppingCategoryRepository

    func fetchCategories() async throws -> [ShoppingCategoryDefinition] {
        try await fetchSnapshot().definitions
    }

    func saveCategories(_ categories: [ShoppingCategoryDefinition]) async throws {
        var current: Snapshot
        if let known = await snapshot.get() {
            current = known
        } else {
            current = try await fetchSnapshot()
        }

        let normalizedNew = ShoppingCategoryDefinition.normalizedDefinitions(categories)
        let previousByKey = Self.indexed(current.definitions)
        let newByKey = Self.indexed(normalizedNew)

        // Deletes — never delete the server-fixed category.
        for definition in current.definitions {
            let key = Self.key(for: definition)
            guard newByKey[key] == nil else {
                continue
            }

            guard current.fixedNames.contains(key) == false else {
                continue
            }

            if let serverID = current.serverIDs[key] {
                try await client.delete(Self.categoriesPath + "/\(serverID.uuidString)")
                current.serverIDs[key] = nil
            }
        }

        // Creates + updates.
        for definition in normalizedNew {
            let key = Self.key(for: definition)
            let request = RemoteCategoryRequest(
                name: definition.name,
                iconName: definition.iconName,
                colorHex: RemoteMapping.colorHex(toServer: definition.colorHex)
            )

            if let serverID = current.serverIDs[key] {
                let previous = previousByKey[key]
                let changed = previous == nil
                    || previous?.name != definition.name
                    || previous?.iconName != definition.iconName
                    || previous?.colorHex != definition.colorHex

                if changed {
                    try await client.put(Self.categoriesPath + "/\(serverID.uuidString)", body: request)
                }
            } else {
                // Server generates the UUID; keep it for later updates/deletes.
                let created: RemoteCategoryResponse = try await client.post(Self.categoriesPath, body: request)
                current.serverIDs[key] = created.id
                if created.fixed == true {
                    current.fixedNames.insert(key)
                }
            }
        }

        // Reorder when the mapped UUID sequence changed.
        let desiredOrder = normalizedNew.compactMap { current.serverIDs[Self.key(for: $0)] }
        if desiredOrder != current.orderedIDs, desiredOrder.count > 1 {
            try await client.put(Self.categoriesPath + "/reorder", body: RemoteReorderRequest(ids: desiredOrder))
        }

        current.definitions = normalizedNew
        current.orderedIDs = desiredOrder
        await snapshot.set(current)
    }

    // MARK: - Internals

    private func fetchSnapshot() async throws -> Snapshot {
        let wireCategories: [RemoteCategoryResponse] = try await client.get(Self.categoriesPath)
        let sorted = wireCategories.sorted { ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0) }

        let definitions = ShoppingCategoryDefinition.normalizedDefinitions(
            sorted.map { wire in
                ShoppingCategoryDefinition(
                    name: wire.name,
                    iconName: wire.iconName ?? "tag",
                    colorHex: wire.colorHex.map(RemoteMapping.colorHex(fromServer:)) ?? 0x6B7280
                )
            }
        )

        var serverIDs: [String: UUID] = [:]
        var fixedNames: Set<String> = []
        for wire in sorted {
            let key = ShoppingItem.Category.normalizedIdentifier(for: wire.name)
            serverIDs[key] = wire.id
            if wire.fixed == true {
                fixedNames.insert(key)
            }
        }

        let result = Snapshot(
            definitions: definitions,
            serverIDs: serverIDs,
            fixedNames: fixedNames,
            orderedIDs: sorted.map(\.id)
        )
        await snapshot.set(result)
        return result
    }

    private static func key(for definition: ShoppingCategoryDefinition) -> String {
        ShoppingItem.Category.normalizedIdentifier(for: definition.name)
    }

    private static func indexed(
        _ definitions: [ShoppingCategoryDefinition]
    ) -> [String: ShoppingCategoryDefinition] {
        Dictionary(
            definitions.map { (key(for: $0), $0) },
            uniquingKeysWith: { first, _ in first }
        )
    }
}
