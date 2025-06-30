import Foundation

nonisolated struct OrganizationRemoteDTO: Decodable, Sendable {
    let id: String
    let party: OrganizationPartyRemoteDTO
    let role: String
    let bankAccounts: [OrganizationBankAccountRemoteDTO]
    let defaultBankAccountID: String?
    let isDefault: Bool
    let revision: Int64
    let createdAt: String
    let updatedAt: String
}

nonisolated struct OrganizationUpsertRemoteDTO: Encodable, Sendable {
    let party: OrganizationPartyRemoteDTO
    let role: String
    let bankAccounts: [OrganizationBankAccountRemoteDTO]
    let defaultBankAccountID: String?
    let isDefault: Bool
    let revision: Int64
}

nonisolated struct OrganizationPartyRemoteDTO: Codable, Sendable {
    let displayName: String
    let fullName: String
    let shortName: String
    let taxID: String
    let registrationNumber: String
    let address: String
    let bankName: String
    let bankAccount: String
    let bankCode: String
    let contactName: String
    let phone: String
    let email: String
}

nonisolated struct OrganizationBankAccountRemoteDTO: Codable, Sendable {
    let id: String
    let bankName: String
    let bankAccount: String
    let bankCode: String
    let correspondentAccount: String
    let isDefault: Bool
}

nonisolated struct OrganizationsRemoteResponse: Decodable, Sendable {
    let items: [OrganizationRemoteDTO]
}

nonisolated struct DeleteOrganizationRemoteResponse: Decodable, Sendable {
    let ok: Bool
}
