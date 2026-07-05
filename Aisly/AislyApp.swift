import SwiftUI

@main
struct AislyApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}

/// Chooses between the default local-storage experience and the remote
/// (auth-gated) experience based on the `aisly.remote.enabled` flag. The flag
/// defaults to false, so the app remains fully local unless opted in.
private struct AppRootView: View {
    @State private var isRemoteEnabled = AislyRemoteConfig.isEnabled

    var body: some View {
        if isRemoteEnabled {
            RemoteRootView(onContinueOffline: {
                // The flag itself is cleared by LoginView; flipping the local
                // state swaps the hierarchy to the offline container.
                isRemoteEnabled = false
            })
        } else {
            LocalRootView()
        }
    }
}

/// Original local-only behavior: a container backed by JSON file stores.
private struct LocalRootView: View {
    @State private var container = AppContainer()

    var body: some View {
        container.makeRootView()
    }
}

/// Remote mode: owns the auth session and gates the app content behind it.
private struct RemoteRootView: View {
    @StateObject private var sessionStore: AuthSessionStore
    private let onContinueOffline: () -> Void

    init(onContinueOffline: @escaping () -> Void) {
        _sessionStore = StateObject(
            wrappedValue: AuthSessionStore(
                authClient: AuthAPIClient(baseURL: AislyRemoteConfig.authBaseURL)
            )
        )
        self.onContinueOffline = onContinueOffline
    }

    var body: some View {
        AuthGateView(sessionStore: sessionStore, onContinueOffline: onContinueOffline) {
            RemoteSignedInView(sessionStore: sessionStore)
        }
    }
}

/// Signed-in content: an `AppContainer` wired with the remote repositories.
/// Recreated whenever the user signs in again (the view leaves the hierarchy
/// on sign-out), which also resets the API client and its snapshots.
private struct RemoteSignedInView: View {
    @State private var container: AppContainer

    init(sessionStore: AuthSessionStore) {
        _container = State(initialValue: Self.makeRemoteContainer(sessionStore: sessionStore))
    }

    var body: some View {
        container.makeRootView()
    }

    private static func makeRemoteContainer(sessionStore: AuthSessionStore) -> AppContainer {
        let client = AislyAPIClient(
            baseURL: AislyRemoteConfig.apiBaseURL,
            tokenProvider: { await sessionStore.currentToken() },
            onUnauthorized: { await sessionStore.handleUnauthorized() }
        )

        return AppContainer(
            shoppingListRepository: RemoteShoppingListRepository(client: client),
            shoppingCategoryRepository: RemoteShoppingCategoryRepository(client: client),
            shoppingItemCatalogRepository: RemoteShoppingItemCatalogRepository(client: client),
            purchaseHistoryRepository: RemotePurchaseHistoryRepository(client: client)
        )
    }
}
