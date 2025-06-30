import Foundation

nonisolated struct Organization: Identifiable, Codable, Hashable, Sendable {
    enum Role: String, Codable, Sendable {
        case seller
        case buyer
        case mixed

        var title: String {
            switch self {
            case .seller:
                return "Продавец"
            case .buyer:
                return "Покупатель"
            case .mixed:
                return "Контрагент"
            }
        }
    }

    var id: UUID
    var party: DocumentParty
    var role: Role
    var bankAccounts: [OrganizationBankAccount]
    var defaultBankAccountID: UUID?
    var isDefault: Bool
    var createdAt: Date
    var updatedAt: Date

    var matchingKey: String {
        let taxID = party.taxID
            .filter(\.isNumber)

        if taxID.isEmpty == false {
            return "tax:\(taxID)"
        }

        return "name:\(party.displayName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))"
    }

    init(
        id: UUID = UUID(),
        party: DocumentParty,
        role: Role,
        bankAccounts: [OrganizationBankAccount] = [],
        defaultBankAccountID: UUID? = nil,
        isDefault: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.party = party
        self.role = role
        self.bankAccounts = bankAccounts
        self.defaultBankAccountID = defaultBankAccountID
        self.isDefault = isDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var normalizedBankAccounts: [OrganizationBankAccount] {
        let storedAccounts = bankAccounts.filter { $0.isEmpty == false }
        if storedAccounts.isEmpty == false {
            return storedAccounts
        }

        let account = OrganizationBankAccount(
            bankName: party.bankName,
            bankAccount: party.bankAccount,
            bankCode: party.bankCode,
            isDefault: true
        )

        return account.isEmpty ? [] : [account]
    }

    var defaultBankAccount: OrganizationBankAccount? {
        let accounts = normalizedBankAccounts
        return accounts.first { $0.id == defaultBankAccountID }
            ?? accounts.first { $0.isDefault }
            ?? accounts.first
    }
}

extension Organization {
    enum CodingKeys: String, CodingKey {
        case id
        case party
        case role
        case bankAccounts
        case defaultBankAccountID
        case isDefault
        case createdAt
        case updatedAt
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        party = try container.decode(DocumentParty.self, forKey: .party)
        role = try container.decode(Role.self, forKey: .role)
        bankAccounts = try container.decodeIfPresent([OrganizationBankAccount].self, forKey: .bankAccounts) ?? []
        defaultBankAccountID = try container.decodeIfPresent(UUID.self, forKey: .defaultBankAccountID)
        isDefault = try container.decodeIfPresent(Bool.self, forKey: .isDefault) ?? false
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}
