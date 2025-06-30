import Foundation

nonisolated enum OrganizationRemoteMapper {
    static func makeOrganization(from dto: OrganizationRemoteDTO) throws -> Organization {
        guard let id = UUID(uuidString: dto.id) else {
            throw MappingError.invalidIdentifier
        }
        return Organization(
            id: id,
            party: makeParty(from: dto.party),
            role: try makeRole(dto.role),
            bankAccounts: try dto.bankAccounts.map(makeBankAccount),
            defaultBankAccountID: dto.defaultBankAccountID.flatMap(UUID.init(uuidString:)),
            isDefault: dto.isDefault,
            createdAt: try makeDate(dto.createdAt),
            updatedAt: try makeDate(dto.updatedAt)
        )
    }

    static func makeUpsertDTO(from organization: Organization, revision: Int64) -> OrganizationUpsertRemoteDTO {
        let bankAccounts = organization.normalizedBankAccounts
        let defaultBankAccountID = organization.defaultBankAccountID
            .flatMap { selectedID in
                bankAccounts.contains(where: { $0.id == selectedID }) ? selectedID : nil
            }
            ?? bankAccounts.first(where: \.isDefault)?.id
            ?? bankAccounts.first?.id

        return OrganizationUpsertRemoteDTO(
            party: makePartyDTO(from: organization.party),
            role: organization.role.rawValue,
            bankAccounts: bankAccounts.map(makeBankAccountDTO),
            defaultBankAccountID: defaultBankAccountID?.uuidString.lowercased(),
            isDefault: organization.isDefault,
            revision: revision
        )
    }
}

private extension OrganizationRemoteMapper {
    enum MappingError: Error {
        case invalidIdentifier
        case invalidRole
        case invalidDate
    }

    nonisolated static func makeParty(from dto: OrganizationPartyRemoteDTO) -> DocumentParty {
        DocumentParty(
            displayName: dto.displayName,
            fullName: dto.fullName,
            shortName: dto.shortName,
            taxID: dto.taxID,
            registrationNumber: dto.registrationNumber,
            address: dto.address,
            bankName: dto.bankName,
            bankAccount: dto.bankAccount,
            bankCode: dto.bankCode,
            contactName: dto.contactName,
            phone: dto.phone,
            email: dto.email
        )
    }

    nonisolated static func makePartyDTO(from party: DocumentParty) -> OrganizationPartyRemoteDTO {
        OrganizationPartyRemoteDTO(
            displayName: party.displayName,
            fullName: party.fullName,
            shortName: party.shortName,
            taxID: party.taxID,
            registrationNumber: party.registrationNumber,
            address: party.address,
            bankName: party.bankName,
            bankAccount: party.bankAccount,
            bankCode: party.bankCode,
            contactName: party.contactName,
            phone: party.phone,
            email: party.email
        )
    }

    nonisolated static func makeBankAccount(from dto: OrganizationBankAccountRemoteDTO) throws -> OrganizationBankAccount {
        guard let id = UUID(uuidString: dto.id) else {
            throw MappingError.invalidIdentifier
        }
        return OrganizationBankAccount(
            id: id,
            bankName: dto.bankName,
            bankAccount: dto.bankAccount,
            bankCode: dto.bankCode,
            correspondentAccount: dto.correspondentAccount,
            isDefault: dto.isDefault
        )
    }

    nonisolated static func makeBankAccountDTO(from account: OrganizationBankAccount) -> OrganizationBankAccountRemoteDTO {
        OrganizationBankAccountRemoteDTO(
            id: account.id.uuidString.lowercased(),
            bankName: account.bankName,
            bankAccount: account.bankAccount,
            bankCode: account.bankCode,
            correspondentAccount: account.correspondentAccount,
            isDefault: account.isDefault
        )
    }

    nonisolated static func makeRole(_ value: String) throws -> Organization.Role {
        guard let role = Organization.Role(rawValue: value) else {
            throw MappingError.invalidRole
        }
        return role
    }

    nonisolated static func makeDate(_ value: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: value) else {
            throw MappingError.invalidDate
        }
        return date
    }
}
