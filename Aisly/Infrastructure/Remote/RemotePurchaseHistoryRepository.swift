import Foundation

/// Remote adapter for `PurchaseHistoryRepository`. History is immutable on
/// the server: new entries come from finishing a list (the server builds the
/// snapshot), removals are DELETEs, and there are no updates.
final class RemotePurchaseHistoryRepository: PurchaseHistoryRepository, Sendable {
    private let client: AislyAPIClient
    private let snapshot = RemoteSnapshotBox<[PurchaseHistoryEntry]>()

    private static let historyPath = "/api/v1/history"
    private static let listsPath = "/api/v1/lists"

    init(client: AislyAPIClient) {
        self.client = client
    }

    // MARK: - PurchaseHistoryRepository

    func fetchEntries() async throws -> [PurchaseHistoryEntry] {
        let wireEntries: [RemoteHistoryEntryResponse] = try await client.get(Self.historyPath)
        let mapped = wireEntries.map(Self.mapToDomain)
        await snapshot.set(mapped)
        return mapped
    }

    func saveEntries(_ entries: [PurchaseHistoryEntry]) async throws {
        let baseline: [PurchaseHistoryEntry]
        if let known = await snapshot.get() {
            baseline = known
        } else {
            baseline = try await fetchEntries()
        }

        let previousByID = Dictionary(baseline.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let currentByID = Dictionary(entries.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        for old in baseline where currentByID[old.id] == nil {
            try await client.delete(Self.historyPath + "/\(old.id.uuidString)")
        }

        var didFinishAnyList = false
        for entry in entries where previousByID[entry.id] == nil {
            // The server builds the snapshot itself (and archives the list)
            // from the current list state; the client supplies the entry id
            // so the operation is idempotent.
            try await client.post(
                Self.listsPath + "/\(entry.sourceListID.uuidString)/finish",
                body: RemoteFinishListRequest(id: entry.id, finishedAt: entry.finishedAt)
            )
            didFinishAnyList = true
        }

        if didFinishAnyList {
            // Refetch so the snapshot reflects the server-computed entries.
            _ = try await fetchEntries()
        } else {
            await snapshot.set(entries)
        }
    }

    // MARK: - Wire → domain mapping

    private static func mapToDomain(_ wire: RemoteHistoryEntryResponse) -> PurchaseHistoryEntry {
        let sections = (wire.sections ?? []).map { wireSection in
            PurchaseHistoryEntry.SectionSnapshot(
                name: wireSection.name,
                items: wireSection.items.map { wireItem in
                    PurchaseHistoryEntry.ItemSnapshot(
                        id: wireItem.id,
                        name: wireItem.name,
                        quantity: wireItem.quantity,
                        sectionName: wireSection.name,
                        storeName: wireItem.storeName,
                        plannedPrice: wireItem.plannedPrice,
                        actualPrice: wireItem.actualPrice,
                        isPurchased: wireItem.purchased,
                        unit: wireItem.unit.flatMap(ShoppingItem.Unit.init(rawValue:))
                    )
                }
            )
        }

        let allItems = sections.flatMap(\.items)

        return PurchaseHistoryEntry(
            id: wire.id,
            // The server always sets sourceListId for finished lists; fall
            // back to the entry id only to satisfy the non-optional field.
            sourceListID: wire.sourceListId ?? wire.id,
            sourceTemplateID: wire.sourceTemplateId,
            name: wire.name,
            finishedAt: wire.finishedAt,
            budget: wire.budget,
            plannedTotal: wire.plannedTotal ?? .zero,
            actualTotal: wire.actualTotal ?? .zero,
            budgetDelta: wire.budgetDelta,
            planDelta: wire.planDelta,
            purchasedItemCount: wire.purchasedItemCount ?? allItems.count,
            missingActualPriceCount: wire.missingActualPriceCount ?? allItems.filter { $0.actualPrice == nil }.count,
            sections: sections,
            totalItemCount: wire.totalItemCount
        )
    }
}
