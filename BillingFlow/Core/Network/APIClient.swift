import Foundation

protocol APIClientProtocol: Sendable {
    func request<Response: Decodable>(
        _ endpoint: APIEndpoint,
        body: Encodable?
    ) async throws -> Response
}

protocol APIAuthorizationProvider: Sendable {
    func accessToken() async -> String?
    func refreshAccessToken() async throws -> String?
}

struct APIClient: APIClientProtocol {
    private let baseURL: URL
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let authorizationProvider: APIAuthorizationProvider?

    init(
        baseURL: URL,
        session: URLSession = .shared,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder(),
        authorizationProvider: APIAuthorizationProvider? = nil
    ) {
        self.baseURL = baseURL
        self.session = session
        self.encoder = encoder
        self.decoder = decoder
        self.authorizationProvider = authorizationProvider
    }

    func request<Response: Decodable>(
        _ endpoint: APIEndpoint,
        body: Encodable? = nil
    ) async throws -> Response {
        let accessToken = await authorizationProvider?.accessToken()
        let result = try await perform(endpoint, body: body, accessToken: accessToken)

        if result.response.statusCode == 401, let authorizationProvider {
            let refreshedToken = try await authorizationProvider.refreshAccessToken()
            guard let refreshedToken else {
                throw serverError(from: result.data, response: result.response)
            }
            let retryResult = try await perform(endpoint, body: body, accessToken: refreshedToken)
            return try decode(retryResult.data, response: retryResult.response)
        }

        return try decode(result.data, response: result.response)
    }

    private func perform(
        _ endpoint: APIEndpoint,
        body: Encodable?,
        accessToken: String?
    ) async throws -> (data: Data, response: HTTPURLResponse) {
        let request = try makeRequest(endpoint, body: body, accessToken: accessToken)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw APIError.network(error.code)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        return (data, httpResponse)
    }

    private func decode<Response: Decodable>(
        _ data: Data,
        response: HTTPURLResponse
    ) throws -> Response {
        guard (200...299).contains(response.statusCode) else {
            throw serverError(from: data, response: response)
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    private func serverError(from data: Data, response: HTTPURLResponse) -> APIError {
        let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data)
        return .server(statusCode: response.statusCode, message: errorResponse?.error)
    }

    private func makeRequest(
        _ endpoint: APIEndpoint,
        body: Encodable?,
        accessToken: String?
    ) throws -> URLRequest {
        let normalizedPath = endpoint.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var components = URLComponents(
            url: baseURL.appendingPathComponent(normalizedPath),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return request
    }
}

private struct APIErrorResponse: Decodable {
    let error: String
}

private struct AnyEncodable: Encodable {
    private let encodeValue: (Encoder) throws -> Void

    init(_ value: Encodable) {
        encodeValue = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeValue(encoder)
    }
}
