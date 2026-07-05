import Foundation

/// Minimal client for the standalone auth server (no bearer token required for
/// register/login; account deletion requires a bearer token). Paths are built
/// under the server's `/api` context path.
final class AuthAPIClient: Sendable {
    private let baseURL: URL
    private let session: URLSession

    // Path segments composed to keep dotted-literal lint rules happy and to
    // avoid embedding the `/api` prefix in the configured base URL.
    private static let usersPath = "/api/users"
    private static let loginPath = "/api/users/login"

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    /// `POST /api/users` — creates the account. Returns the created user; the
    /// server does not issue a token on registration.
    func register(email: String, password: String, name: String) async throws -> UserWire {
        try await send(
            method: "POST",
            path: Self.usersPath,
            body: CreateUserWire(email: email, password: password, name: name),
            bearerToken: nil
        )
    }

    /// `POST /api/users/login` — exchanges credentials for a bearer token.
    func login(email: String, password: String) async throws -> LoginResponseWire {
        try await send(
            method: "POST",
            path: Self.loginPath,
            body: LoginWire(email: email, password: password),
            bearerToken: nil
        )
    }

    /// `DELETE /api/users/{id}` — removes the account. Requires a bearer token.
    func deleteAccount(id: String, token: String) async throws {
        let path = Self.usersPath + "/" + id
        let _: EmptyBody = try await send(
            method: "DELETE",
            path: path,
            body: Optional<EmptyBody>.none,
            bearerToken: token
        )
    }

    // MARK: - Transport

    private struct EmptyBody: Codable, Sendable {}

    private func send<Body: Encodable, Response: Decodable>(
        method: String,
        path: String,
        body: Body?,
        bearerToken: String?
    ) async throws -> Response {
        guard let url = URL(string: path, relativeTo: baseURL)?.absoluteURL else {
            throw AislyAPIError.network(underlying: URLError(.badURL))
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let bearerToken {
            request.setValue("Bearer " + bearerToken, forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                request.httpBody = try AislyAPIJSONCoding.makeEncoder().encode(body)
            } catch {
                throw AislyAPIError.decoding(underlying: error)
            }
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AislyAPIError.network(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AislyAPIError.network(underlying: URLError(.badServerResponse))
        }

        switch httpResponse.statusCode {
        case 200..<300:
            if Response.self == EmptyBody.self {
                return EmptyBody() as! Response
            }
            do {
                return try AislyAPIJSONCoding.makeDecoder().decode(Response.self, from: data)
            } catch {
                throw AislyAPIError.decoding(underlying: error)
            }
        case 401:
            throw AislyAPIError.unauthorized
        default:
            let errorBody = try? AislyAPIJSONCoding.makeDecoder().decode(SpringErrorBody.self, from: data)
            throw AislyAPIError.server(
                status: httpResponse.statusCode,
                message: errorBody?.message ?? errorBody?.error
            )
        }
    }
}
