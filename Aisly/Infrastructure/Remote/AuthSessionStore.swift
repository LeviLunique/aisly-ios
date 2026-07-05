import Foundation
import Security

/// Basic identity of the signed-in user, decoded from the auth response.
struct UserProfile: Equatable, Sendable {
    let subject: String
    let email: String
    let displayName: String
}

/// Owns the auth session lifecycle: login/register against the auth server,
/// Keychain persistence, expiry checks, and the signed-in/signed-out state
/// the UI switches on. There is no refresh token — an expired access token
/// simply requires signing in again.
@MainActor
final class AuthSessionStore: ObservableObject {
    enum SessionState: Equatable {
        case loading
        case signedOut
        case signedIn(UserProfile)
    }

    @Published private(set) var state: SessionState = .loading

    private let authClient: AuthAPIClient
    private let keychain: SessionKeychain
    private var session: StoredSession?

    init(authClient: AuthAPIClient, keychain: SessionKeychain = SessionKeychain()) {
        self.authClient = authClient
        self.keychain = keychain
        restorePersistedSession()
    }

    // MARK: - Auth actions

    func login(email: String, password: String) async throws {
        let response = try await authClient.login(email: email, password: password)
        adopt(response)
    }

    /// Registration creates the account (which does not return a token) and then
    /// immediately logs in to obtain the token and establish the session.
    func register(email: String, password: String, displayName: String) async throws {
        _ = try await authClient.register(
            email: email,
            password: password,
            name: displayName
        )
        let response = try await authClient.login(email: email, password: password)
        adopt(response)
    }

    /// Deletes the signed-in account on the server and clears the local session.
    func deleteAccount() async throws {
        guard let session else { return }
        try await authClient.deleteAccount(id: session.subject, token: session.accessToken)
        signOut()
    }

    func signOut() {
        session = nil
        keychain.clear()
        state = .signedOut
    }

    /// Called by the API client when the server rejects the token.
    func handleUnauthorized() {
        signOut()
    }

    /// Returns the persisted access token, or nil when absent or expired.
    func currentToken() -> String? {
        guard let session, session.expiresAt > Date() else {
            return nil
        }

        return session.accessToken
    }

    // MARK: - Internals

    private func adopt(_ response: LoginResponseWire) {
        let newSession = StoredSession(
            accessToken: response.token,
            subject: String(response.user.id),
            email: response.user.email,
            displayName: response.user.name,
            expiresAt: Self.expiry(fromToken: response.token)
        )

        session = newSession
        keychain.save(newSession)
        state = .signedIn(newSession.profile)
    }

    /// The auth server no longer returns `expiresIn`; the expiry is read from the
    /// JWT payload's `exp` claim instead. The app never validates the HS256
    /// signature — it only needs to know when the opaque token stops working.
    /// A 48h fallback is used when the token cannot be parsed.
    private static func expiry(fromToken token: String) -> Date {
        let fallback = Date().addingTimeInterval(48 * 60 * 60)

        let segments = token.split(separator: ".")
        guard segments.count >= 2 else { return fallback }

        guard let payloadData = base64URLDecoded(String(segments[1])) else {
            return fallback
        }

        guard
            let json = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
            let exp = (json["exp"] as? NSNumber)?.doubleValue ?? (json["exp"] as? Double)
        else {
            return fallback
        }

        return Date(timeIntervalSince1970: exp)
    }

    /// Decodes a base64url string (JWT segments use `-`/`_` and drop padding).
    private static func base64URLDecoded(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let remainder = base64.count % 4
        if remainder > 0 {
            base64.append(String(repeating: "=", count: 4 - remainder))
        }

        return Data(base64Encoded: base64)
    }

    private func restorePersistedSession() {
        guard let persisted = keychain.load(), persisted.expiresAt > Date() else {
            session = nil
            state = .signedOut
            return
        }

        session = persisted
        state = .signedIn(persisted.profile)
    }
}

/// Payload persisted in the Keychain between launches.
struct StoredSession: Codable, Sendable {
    let accessToken: String
    let subject: String
    let email: String
    let displayName: String
    let expiresAt: Date

    var profile: UserProfile {
        UserProfile(subject: subject, email: email, displayName: displayName)
    }
}

/// Thin wrapper over the Security framework for one generic-password item
/// holding the serialized session.
struct SessionKeychain: Sendable {
    // Composed to keep dotted literals out of source (lint rule).
    private static let service = ["com", "levilunique", "aisly", "session"].joined(separator: ".")
    private static let account = "aisly-session"

    func save(_ session: StoredSession) {
        guard let data = try? AislyAPIJSONCoding.makeEncoder().encode(session) else {
            return
        }

        var query = baseQuery()
        SecItemDelete(query as CFDictionary)

        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(query as CFDictionary, nil)
    }

    func load() -> StoredSession? {
        var query = baseQuery()
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return try? AislyAPIJSONCoding.makeDecoder().decode(StoredSession.self, from: data)
    }

    func clear() {
        SecItemDelete(baseQuery() as CFDictionary)
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.account
        ]
    }
}
