import Foundation

enum AppRoute: Hashable {
    case home
    case listDetail(UUID)
    case shoppingMode(UUID)

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

        switch routeName {
        case nil, "", "home":
            self = .home
        case "list":
            guard let listID else {
                return nil
            }
            self = .listDetail(listID)
        case "shopping-mode":
            guard let listID else {
                return nil
            }
            self = .shoppingMode(listID)
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
        case .shoppingMode(let listID):
            components.host = "shopping-mode"
            components.queryItems = [URLQueryItem(name: "listID", value: listID.uuidString)]
        }

        return components.url ?? URL(string: "aisly://home")!
    }
}
