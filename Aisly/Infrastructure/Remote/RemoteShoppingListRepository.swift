import Foundation

/// Remote adapter for `ShoppingListRepository`. The iOS domain keeps lists and
/// templates in one array; the server splits them across `/lists` and
/// `/templates`. Saves are diffed per entity against the last fetched server
/// snapshot and translated into the corresponding REST calls.
final class RemoteShoppingListRepository: ShoppingListRepository, Sendable {
    private let client: AislyAPIClient
    private let snapshot = RemoteSnapshotBox<[ShoppingList]>()

    private static let listsPath = "/api/v1/lists"
    private static let templatesPath = "/api/v1/templates"
    private static let includeArchivedQuery = [URLQueryItem(name: "includeArchived", value: "true")]

    init(client: AislyAPIClient) {
        self.client = client
    }

    // MARK: - ShoppingListRepository

    func fetchLists() async throws -> [ShoppingList] {
        async let listsCall: [RemoteListResponse] = client.get(
            Self.listsPath,
            queryItems: Self.includeArchivedQuery
        )
        async let templatesCall: [RemoteListResponse] = client.get(
            Self.templatesPath,
            queryItems: Self.includeArchivedQuery
        )

        let (lists, templates) = try await (listsCall, templatesCall)
        let mapped = (lists + templates).map(Self.mapToDomain)
        await snapshot.set(mapped)
        return mapped
    }

    func saveLists(_ lists: [ShoppingList]) async throws {
        let baseline: [ShoppingList]
        if let known = await snapshot.get() {
            baseline = known
        } else {
            // No known server state yet — establish a baseline so the diff
            // does not re-create everything.
            baseline = try await fetchLists()
        }

        try await pushDiff(from: baseline, to: lists)
        await snapshot.set(lists)
    }

    // MARK: - Diffing

    private func pushDiff(from previous: [ShoppingList], to current: [ShoppingList]) async throws {
        let previousByID = Self.indexed(previous)
        let currentByID = Self.indexed(current)

        // Deletes first so name/order collisions cannot occur server-side.
        for old in previous where currentByID[old.id] == nil {
            try await client.delete(Self.entityPath(for: old))
        }

        for list in current where previousByID[list.id] == nil {
            try await create(list)
        }

        for list in current {
            guard let old = previousByID[list.id] else {
                continue
            }

            try await pushListUpdate(from: old, to: list)
        }

        // Manual ordering of active (non-archived, non-template) lists.
        let previousActiveIDs = Self.activeListIDs(previous)
        let currentActiveIDs = Self.activeListIDs(current)
        if currentActiveIDs != previousActiveIDs, currentActiveIDs.count > 1 {
            try await client.put(
                Self.listsPath + "/reorder",
                body: RemoteReorderRequest(ids: currentActiveIDs)
            )
        }
    }

    private func create(_ list: ShoppingList) async throws {
        let orderedItems = Self.orderedItems(list.items)
        let itemRequests = orderedItems.map { RemoteItemRequest(item: $0, includeID: true) }

        if let recurrence = list.templateRecurrence {
            try await client.post(
                Self.templatesPath,
                body: RemoteCreateTemplateRequest(
                    id: list.id,
                    name: list.name,
                    recurrence: recurrence.rawValue,
                    sourceListId: nil,
                    budget: list.budget,
                    iconName: list.iconName,
                    colorHex: RemoteMapping.colorHex(toServer: list.colorHex),
                    items: itemRequests
                )
            )
        } else {
            try await client.post(
                Self.listsPath,
                body: RemoteCreateListRequest(
                    id: list.id,
                    name: list.name,
                    budget: list.budget,
                    iconName: list.iconName,
                    colorHex: RemoteMapping.colorHex(toServer: list.colorHex),
                    sourceTemplateId: list.sourceTemplateID,
                    categories: list.categories.map(\.rawValue),
                    items: itemRequests
                )
            )

            if list.isPinned {
                try await client.patch(
                    Self.listsPath + "/\(list.id.uuidString)/pin",
                    body: RemotePinRequest(pinned: true)
                )
            }
        }

        if list.isArchived {
            try await client.patch(
                Self.entityPath(for: list) + "/archive",
                body: RemoteArchiveRequest(archived: true)
            )
        }
    }

    private func pushListUpdate(from old: ShoppingList, to new: ShoppingList) async throws {
        let idPath = Self.listsPath + "/\(new.id.uuidString)"

        // Metadata (name/budget/icon/color/categories).
        // TODO(server contract): templates have no documented PUT endpoint;
        // metadata and item edits on templates reuse the /lists routes on the
        // assumption that templates share the list entity server-side.
        if Self.metadataChanged(from: old, to: new) {
            try await client.put(
                idPath,
                body: RemoteUpdateListRequest(
                    name: new.name,
                    budget: new.budget,
                    iconName: new.iconName,
                    colorHex: RemoteMapping.colorHex(toServer: new.colorHex),
                    categories: new.categories.map(\.rawValue)
                )
            )
        }

        if old.isPinned != new.isPinned, new.isTemplate == false {
            try await client.patch(idPath + "/pin", body: RemotePinRequest(pinned: new.isPinned))
        }

        if old.isArchived != new.isArchived {
            try await client.patch(
                Self.entityPath(for: new) + "/archive",
                body: RemoteArchiveRequest(archived: new.isArchived)
            )
        }

        try await pushItemsDiff(listID: new.id, from: old.items, to: new.items)
    }

    private func pushItemsDiff(
        listID: UUID,
        from previous: [ShoppingItem],
        to current: [ShoppingItem]
    ) async throws {
        let itemsPath = Self.listsPath + "/\(listID.uuidString)/items"
        let previousByID = Dictionary(previous.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let currentByID = Dictionary(current.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        for old in previous where currentByID[old.id] == nil {
            try await client.delete(itemsPath + "/\(old.id.uuidString)")
        }

        for item in Self.orderedItems(current) where previousByID[item.id] == nil {
            try await client.post(itemsPath, body: RemoteItemRequest(item: item, includeID: true))
        }

        for item in current {
            guard let old = previousByID[item.id] else {
                continue
            }

            let contentChanged = Self.itemContentChanged(from: old, to: item)
            let completionChanged = old.isCompleted != item.isCompleted

            if contentChanged {
                // PUT carries `completed` too, so it covers combined edits.
                try await client.put(
                    itemsPath + "/\(item.id.uuidString)",
                    body: RemoteItemRequest(item: item, includeID: false)
                )
            } else if completionChanged {
                try await client.patch(
                    itemsPath + "/\(item.id.uuidString)/completion",
                    body: RemoteCompletionRequest(completed: item.isCompleted)
                )
            }
        }

        let previousOrder = Self.orderedItems(previous).map(\.id)
        let currentOrder = Self.orderedItems(current).map(\.id)
        if currentOrder != previousOrder, currentOrder.count > 1 {
            try await client.put(itemsPath + "/reorder", body: RemoteReorderRequest(ids: currentOrder))
        }
    }

    // MARK: - Comparison helpers

    private static func metadataChanged(from old: ShoppingList, to new: ShoppingList) -> Bool {
        old.name != new.name
            || old.budget != new.budget
            || old.iconName != new.iconName
            || old.colorHex != new.colorHex
            || old.categories.map(\.rawValue) != new.categories.map(\.rawValue)
    }

    private static func itemContentChanged(from old: ShoppingItem, to new: ShoppingItem) -> Bool {
        old.name != new.name
            || old.quantity != new.quantity
            || old.unit != new.unit
            || old.category.rawValue != new.category.rawValue
            || old.storeName != new.storeName
            || old.plannedPrice != new.plannedPrice
            || old.actualPrice != new.actualPrice
            || old.note != new.note
            || old.isFavorite != new.isFavorite
    }

    private static func indexed(_ lists: [ShoppingList]) -> [UUID: ShoppingList] {
        Dictionary(lists.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    private static func activeListIDs(_ lists: [ShoppingList]) -> [UUID] {
        lists
            .filter { $0.isTemplate == false && $0.isArchived == false }
            .map(\.id)
    }

    private static func orderedItems(_ items: [ShoppingItem]) -> [ShoppingItem] {
        items.sorted { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.createdAt < rhs.createdAt
            }

            return lhs.sortOrder < rhs.sortOrder
        }
    }

    private static func entityPath(for list: ShoppingList) -> String {
        (list.isTemplate ? Self.templatesPath : Self.listsPath) + "/\(list.id.uuidString)"
    }

    // MARK: - Wire → domain mapping

    static func mapToDomain(_ wire: RemoteListResponse) -> ShoppingList {
        let fallbackDate = wire.createdAt ?? Date()
        let items = (wire.items ?? []).enumerated().map { index, wireItem in
            ShoppingItem(
                id: wireItem.id,
                name: wireItem.name,
                quantity: wireItem.quantity,
                category: ShoppingItem.Category(wireItem.categoryName ?? ""),
                storeName: wireItem.storeName,
                plannedPrice: wireItem.plannedPrice,
                actualPrice: wireItem.actualPrice,
                isCompleted: wireItem.completed,
                createdAt: wireItem.createdAt ?? fallbackDate,
                updatedAt: wireItem.updatedAt ?? wireItem.createdAt ?? fallbackDate,
                sortOrder: wireItem.sortOrder ?? index,
                unit: RemoteMapping.unit(fromServer: wireItem.unit),
                note: wireItem.note ?? "",
                isFavorite: wireItem.favorite ?? false
            )
        }
        let sortedItems = orderedItems(items)

        let explicitCategories = (wire.categories ?? []).map(ShoppingItem.Category.init)
        let categories = ShoppingList.normalizedCategories(explicitCategories + sortedItems.map(\.category))

        let templateConfiguration = wire.templateRecurrence
            .flatMap(ShoppingList.TemplateRecurrence.init(rawValue:))
            .map(ShoppingList.TemplateConfiguration.init(recurrence:))

        return ShoppingList(
            id: wire.id,
            name: wire.name,
            createdAt: wire.createdAt ?? fallbackDate,
            updatedAt: wire.updatedAt ?? wire.createdAt ?? fallbackDate,
            isArchived: wire.archived,
            budget: wire.budget,
            iconName: wire.iconName ?? ShoppingList.defaultIconName,
            colorHex: wire.colorHex.map(RemoteMapping.colorHex(fromServer:)) ?? ShoppingList.defaultColorHex,
            categories: categories.isEmpty ? ShoppingItem.Category.defaultCategories : categories,
            items: sortedItems,
            templateConfiguration: templateConfiguration,
            sourceTemplateID: wire.sourceTemplateId,
            isPinned: wire.pinned ?? false
        )
    }
}
