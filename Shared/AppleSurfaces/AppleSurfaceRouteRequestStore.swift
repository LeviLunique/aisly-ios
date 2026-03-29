import Foundation

enum AppleSurfaceRouteRequestStore {
    private static let pendingRouteKey = "appleSurface.pendingRoute"

    static func savePendingRoute(
        _ route: AppRoute,
        userDefaults: UserDefaults? = sharedUserDefaults
    ) {
        userDefaults?.set(route.url.absoluteString, forKey: pendingRouteKey)
    }

    static func consumePendingRoute(
        userDefaults: UserDefaults? = sharedUserDefaults
    ) -> AppRoute? {
        guard
            let userDefaults,
            let routeValue = userDefaults.string(forKey: pendingRouteKey),
            let routeURL = URL(string: routeValue),
            let route = AppRoute(url: routeURL)
        else {
            return nil
        }

        userDefaults.removeObject(forKey: pendingRouteKey)
        return route
    }

    private static var sharedUserDefaults: UserDefaults? {
        UserDefaults(suiteName: AppStoragePaths.appGroupIdentifier) ?? .standard
    }
}
