import Foundation

protocol AuthServiceProtocol: Sendable {
    func requestCode(phone: String) async throws -> PhoneChallenge
    func verify(challengeID: String, code: String) async throws -> AuthUser
}

struct RemoteAuthService: AuthServiceProtocol {
    private let apiClient: APIClient
    private let authSession: AuthSession

    init(apiClient: APIClient, authSession: AuthSession) {
        self.apiClient = apiClient
        self.authSession = authSession
    }

    func requestCode(phone: String) async throws -> PhoneChallenge {
        try await apiClient.request(
            APIEndpoint(path: "/v1/billing/auth/phone/request", method: .post),
            body: PhoneRequestBody(phone: phone)
        )
    }

    func verify(challengeID: String, code: String) async throws -> AuthUser {
        let response: AuthResponse = try await apiClient.request(
            APIEndpoint(path: "/v1/billing/auth/phone/verify", method: .post),
            body: PhoneVerifyBody(challengeId: challengeID, code: code)
        )
        try await authSession.apply(response)
        return response.user
    }
}
