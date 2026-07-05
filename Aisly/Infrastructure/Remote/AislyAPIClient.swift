import Foundation

/// Errors surfaced by `AislyAPIClient` and the remote repositories.
enum AislyAPIError: Error {
    case unauthorized
    case server(status: Int, message: String?)
    case network(underlying: Error)
    case decoding(underlying: Error)
}

/// Shape of Spring's default error body (`{"status": 401, "error": "...", "message": "..."}`).
struct SpringErrorBody: Decodable, Sendable {
    let message: String?
    let error: String?
}

/// JSON coding helpers shared by the API clients. The date strategies accept
/// ISO-8601 instants both with and without fractional seconds.
enum AislyAPIJSONCoding {
    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)

            if let date = parseInstant(rawValue) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unrecognized ISO-8601 instant: \(rawValue)"
            )
        }
        return decoder
    }

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(formatInstant(date))
        }
        return encoder
    }

    static func parseInstant(_ rawValue: String) -> Date? {
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractionalFormatter.date(from: rawValue) {
            return date
        }

        let plainFormatter = ISO8601DateFormatter()
        plainFormatter.formatOptions = [.withInternetDateTime]
        return plainFormatter.date(from: rawValue)
    }

    static func formatInstant(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}

/// URLSession-backed JSON client for the Aisly API server. Attaches a bearer
/// token from the injected async token provider and reports 401 responses to
/// `onUnauthorized` exactly once for the lifetime of the client.
final class AislyAPIClient: Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let tokenProvider: @Sendable () async -> String?
    private let onUnauthorized: @Sendable () async -> Void
    private let unauthorizedGate = OnceGate()

    init(
        baseURL: URL,
        session: URLSession = .shared,
        tokenProvider: @escaping @Sendable () async -> String?,
        onUnauthorized: @escaping @Sendable () async -> Void
    ) {
        self.baseURL = baseURL
        self.session = session
        self.tokenProvider = tokenProvider
        self.onUnauthorized = onUnauthorized
    }

    // MARK: - Typed verbs

    func get<Response: Decodable & Sendable>(
        _ path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> Response {
        try await requestDecoding(method: "GET", path: path, queryItems: queryItems, body: nil as Data?)
    }

    func post<Body: Encodable & Sendable, Response: Decodable & Sendable>(
        _ path: String,
        body: Body
    ) async throws -> Response {
        try await requestDecoding(method: "POST", path: path, body: try encodeBody(body))
    }

    func post<Body: Encodable & Sendable>(_ path: String, body: Body) async throws {
        try await requestIgnoringResponse(method: "POST", path: path, body: try encodeBody(body))
    }

    func post(_ path: String) async throws {
        try await requestIgnoringResponse(method: "POST", path: path, body: nil)
    }

    func put<Body: Encodable & Sendable>(_ path: String, body: Body) async throws {
        try await requestIgnoringResponse(method: "PUT", path: path, body: try encodeBody(body))
    }

    func patch<Body: Encodable & Sendable>(_ path: String, body: Body) async throws {
        try await requestIgnoringResponse(method: "PATCH", path: path, body: try encodeBody(body))
    }

    func delete(_ path: String) async throws {
        try await requestIgnoringResponse(method: "DELETE", path: path, body: nil)
    }

    // MARK: - Core request pipeline

    private func requestDecoding<Response: Decodable & Sendable>(
        method: String,
        path: String,
        queryItems: [URLQueryItem] = [],
        body: Data?
    ) async throws -> Response {
        let data = try await perform(method: method, path: path, queryItems: queryItems, body: body)

        do {
            return try AislyAPIJSONCoding.makeDecoder().decode(Response.self, from: data)
        } catch {
            throw AislyAPIError.decoding(underlying: error)
        }
    }

    private func requestIgnoringResponse(
        method: String,
        path: String,
        body: Data?
    ) async throws {
        _ = try await perform(method: method, path: path, queryItems: [], body: body)
    }

    private func perform(
        method: String,
        path: String,
        queryItems: [URLQueryItem],
        body: Data?
    ) async throws -> Data {
        var components = URLComponents()
        components.path = path
        if queryItems.isEmpty == false {
            components.queryItems = queryItems
        }

        guard let url = components.url(relativeTo: baseURL)?.absoluteURL else {
            throw AislyAPIError.network(underlying: URLError(.badURL))
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if let token = await tokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
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
            return data
        case 401:
            if await unauthorizedGate.tryPass() {
                await onUnauthorized()
            }
            throw AislyAPIError.unauthorized
        default:
            let errorBody = try? AislyAPIJSONCoding.makeDecoder().decode(SpringErrorBody.self, from: data)
            throw AislyAPIError.server(
                status: httpResponse.statusCode,
                message: errorBody?.message ?? errorBody?.error
            )
        }
    }

    private func encodeBody<Body: Encodable>(_ body: Body) throws -> Data {
        do {
            return try AislyAPIJSONCoding.makeEncoder().encode(body)
        } catch {
            throw AislyAPIError.decoding(underlying: error)
        }
    }
}

/// Actor gate that lets exactly one caller pass, ever. Used to fire the
/// unauthorized callback a single time per client lifetime.
private actor OnceGate {
    private var hasPassed = false

    func tryPass() -> Bool {
        guard hasPassed == false else {
            return false
        }

        hasPassed = true
        return true
    }
}
