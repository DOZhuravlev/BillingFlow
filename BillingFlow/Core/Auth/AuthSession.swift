import Foundation

actor AuthSession: APIAuthorizationProvider {
    private enum Key {
        static let refreshToken = "billing.refresh-token"
        static let userID = "billing.user-id"
        static let userPhone = "billing.user-phone"
    }

    private let apiClient: APIClient
    private let keychain: KeychainStore

    private var user: AuthUser?
    private var currentAccessToken: String?
    private var accessTokenExpiresAt: Date?
    private var refreshTask: Task<AuthResponse, Error>?

    init(baseURL: URL, keychain: KeychainStore) {
        self.apiClient = APIClient(baseURL: baseURL)
        self.keychain = keychain
        if keychain.string(for: Key.refreshToken) != nil,
           let id = keychain.string(for: Key.userID),
           let phone = keychain.string(for: Key.userPhone) {
            self.user = AuthUser(id: id, phone: phone)
        }
    }

    func accessToken() -> String? {
        guard let accessTokenExpiresAt,
              accessTokenExpiresAt.timeIntervalSinceNow > 15 else {
            return nil
        }
        return currentAccessToken
    }

    func refreshAccessToken() async throws -> String? {
        if let refreshTask {
            return try await refreshTask.value.accessToken
        }
        guard let refreshToken = keychain.string(for: Key.refreshToken) else {
            return nil
        }

        let apiClient = apiClient
        let task = Task<AuthResponse, Error> {
            try await apiClient.request(
                APIEndpoint(path: "/v1/billing/auth/refresh", method: .post),
                body: RefreshTokenBody(refreshToken: refreshToken)
            )
        }
        refreshTask = task

        do {
            let response = try await task.value
            refreshTask = nil
            try apply(response)
            return response.accessToken
        } catch {
            refreshTask = nil
            if case APIError.server(let statusCode, _) = error, statusCode == 401 {
                clear()
            }
            throw error
        }
    }

    func restoreUser() async -> AuthUser? {
        if let user {
            return user
        }
        guard keychain.string(for: Key.refreshToken) != nil else {
            return nil
        }
        do {
            _ = try await refreshAccessToken()
            return user
        } catch {
            return nil
        }
    }

    func apply(_ response: AuthResponse) throws {
        try keychain.set(response.refreshToken, for: Key.refreshToken)
        try keychain.set(response.user.id, for: Key.userID)
        try keychain.set(response.user.phone, for: Key.userPhone)
        user = response.user
        currentAccessToken = response.accessToken
        accessTokenExpiresAt = Date().addingTimeInterval(TimeInterval(response.accessTokenExpiresIn))
    }

    func logout() async {
        if let refreshToken = keychain.string(for: Key.refreshToken) {
            let _: LogoutResponse? = try? await apiClient.request(
                APIEndpoint(path: "/v1/billing/auth/logout", method: .post),
                body: RefreshTokenBody(refreshToken: refreshToken)
            )
        }
        clear()
    }

    func currentUserID() -> String? {
        guard keychain.string(for: Key.refreshToken) != nil else { return nil }
        return user?.id ?? keychain.string(for: Key.userID)
    }

    private func clear() {
        user = nil
        currentAccessToken = nil
        accessTokenExpiresAt = nil
        keychain.removeValue(for: Key.refreshToken)
        keychain.removeValue(for: Key.userID)
        keychain.removeValue(for: Key.userPhone)
    }
}
