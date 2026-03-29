import AppIntents
import Foundation

struct ShoppingListAppEntity: AppEntity, Identifiable, Equatable, Sendable {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: LocalizedStringResource("appleSurface.listEntity.type.title")
    )
    static let defaultQuery = ShoppingListAppEntityQuery()

    let id: UUID
    let name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct ShoppingListAppEntityQuery: EntityQuery {
    func entities(for identifiers: [ShoppingListAppEntity.ID]) async throws -> [ShoppingListAppEntity] {
        let activeLists = try await AppleSurfaceListStore.fetchActiveLists()
        let identifierSet = Set(identifiers)

        return activeLists
            .filter { identifierSet.contains($0.id) }
            .map(ShoppingListAppEntity.init(list:))
    }

    func suggestedEntities() async throws -> [ShoppingListAppEntity] {
        try await AppleSurfaceListStore.fetchActiveLists()
            .prefix(5)
            .map(ShoppingListAppEntity.init(list:))
    }
}

extension ShoppingListAppEntity {
    init(list: ShoppingList) {
        id = list.id
        name = list.name
    }
}
