import SwiftUI

/// Root switcher for remote mode: shows a splash while the persisted session
/// loads, the login flow when signed out, and the injected app content once a
/// valid session exists. A 401 anywhere flips the session store to signedOut,
/// which swaps this view back to Login automatically.
struct AuthGateView<Content: View>: View {
    @ObservedObject private var sessionStore: AuthSessionStore
    private let onContinueOffline: () -> Void
    private let content: () -> Content

    init(
        sessionStore: AuthSessionStore,
        onContinueOffline: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.sessionStore = sessionStore
        self.onContinueOffline = onContinueOffline
        self.content = content
    }

    var body: some View {
        switch sessionStore.state {
        case .loading:
            loadingState
        case .signedOut:
            LoginView(sessionStore: sessionStore, onContinueOffline: onContinueOffline)
        case .signedIn:
            content()
        }
    }

    private var loadingState: some View {
        VStack(spacing: AislySpacing.xxLarge) {
            AislyLogo(size: .large)

            ProgressView()
                .tint(AislyColor.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AislyColor.backgroundPrimary.ignoresSafeArea())
    }
}
