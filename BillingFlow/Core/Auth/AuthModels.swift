import Foundation

nonisolated struct AuthUser: Codable, Equatable, Sendable {
    let id: String
    let phone: String
}

nonisolated struct PhoneChallenge: Decodable, Sendable {
    let challengeId: String
    let expiresIn: Int
    let retryAfter: Int
}

nonisolated struct AuthResponse: Decodable, Sendable {
    let user: AuthUser
    let accessToken: String
    let accessTokenExpiresIn: Int
    let refreshToken: String
}

nonisolated struct PhoneRequestBody: Encodable {
    let phone: String
}

nonisolated struct PhoneVerifyBody: Encodable {
    let challengeId: String
    let code: String
}

nonisolated struct RefreshTokenBody: Encodable {
    let refreshToken: String
}

nonisolated struct LogoutResponse: Decodable {
    let ok: Bool
}
