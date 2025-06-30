import Combine
import Foundation

@MainActor
final class AuthController: ObservableObject {
    @Published private(set) var user: AuthUser?
    @Published private(set) var isRestoring = true

    private let authService: AuthServiceProtocol
    private let authSession: AuthSession
    private let didAuthenticate: @Sendable () async -> Void
    private let willLogout: @Sendable () async -> Void
    private let didLogout: @Sendable () async -> Void

    init(
        authService: AuthServiceProtocol,
        authSession: AuthSession,
        didAuthenticate: @escaping @Sendable () async -> Void = { },
        willLogout: @escaping @Sendable () async -> Void = { },
        didLogout: @escaping @Sendable () async -> Void = { }
    ) {
        self.authService = authService
        self.authSession = authSession
        self.didAuthenticate = didAuthenticate
        self.willLogout = willLogout
        self.didLogout = didLogout
    }

    var isAuthenticated: Bool {
        user != nil
    }

    func restore() async {
        user = await authSession.restoreUser()
        if user != nil {
            await didAuthenticate()
        }
        isRestoring = false
    }

    func requestCode(phone: String) async throws -> PhoneChallenge {
        try await authService.requestCode(phone: phone)
    }

    func verify(challengeID: String, code: String) async throws {
        user = try await authService.verify(challengeID: challengeID, code: code)
        await didAuthenticate()
    }

    func logout() async {
        await willLogout()
        await authSession.logout()
        user = nil
        await didLogout()
    }
}
