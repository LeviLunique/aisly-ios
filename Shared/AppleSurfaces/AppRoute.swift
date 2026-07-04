import Foundation

enum AppRoute: Hashable {
    case home
    case listDetail(UUID)
    case templateDetail(UUID)
    case categories
    case templates
    case itemDatabase
    case history
    case historyDetail(UUID)
    case archivedLists

    init?(url: URL) {
        guard url.scheme == "aisly" else {
            return nil
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let routeName = url.host ?? url.pathComponents.dropFirst().first
        let listID = components?
            .queryItems?
            .first(where: { $0.name == "listID" })?
            .value
            .flatMap(UUID.init(uuidString:))
        let entryID = components?
            .queryItems?
            .first(where: { $0.name == "entryID" })?
            .value
            .flatMap(UUID.init(uuidString:))

        switch routeName {
        case nil, "", "home":
            self = .home
        case "list":
            guard let listID else {
                return nil
            }
            self = .listDetail(listID)
        case "template":
            guard let listID else {
                return nil
            }
            self = .templateDetail(listID)
        case "categories":
            self = .categories
        case "templates":
            self = .templates
        case "items":
            self = .itemDatabase
        case "history":
            self = .history
        case "history-entry":
            guard let entryID else {
                return nil
            }
            self = .historyDetail(entryID)
        case "archived":
            self = .archivedLists
        default:
            return nil
        }
    }

    var url: URL {
        var components = URLComponents()
        components.scheme = "aisly"

        switch self {
        case .home:
            components.host = "home"
        case .listDetail(let listID):
            components.host = "list"
            components.queryItems = [URLQueryItem(name: "listID", value: listID.uuidString)]
        case .templateDetail(let listID):
            components.host = "template"
            components.queryItems = [URLQueryItem(name: "listID", value: listID.uuidString)]
        case .categories:
            components.host = "categories"
        case .templates:
            components.host = "templates"
        case .itemDatabase:
            components.host = "items"
        case .history:
            components.host = "history"
        case .historyDetail(let entryID):
            components.host = "history-entry"
            components.queryItems = [URLQueryItem(name: "entryID", value: entryID.uuidString)]
        case .archivedLists:
            components.host = "archived"
        }

        return components.url ?? URL(string: "aisly://home")!
    }
}
