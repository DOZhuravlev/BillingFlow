import Foundation

nonisolated actor FileOrganizationsRepository: OrganizationsRepositoryProtocol {

    // MARK: - Dependencies

    private let store: LocalOrganizationsStore

    // MARK: - Properties

    private var cachedOrganizations: [Organization]?

    // MARK: - Initialization

    init(store: LocalOrganizationsStore = LocalOrganizationsStore()) {
        self.store = store
    }

    // MARK: - Fetching

    func fetchOrganizations() async throws -> [Organization] {
        let organizations = try loadOrganizationsIfNeeded()
        return organizations.sorted { lhs, rhs in
            lhs.updatedAt > rhs.updatedAt
        }
    }

    // MARK: - Mutating

    func save(organization: Organization) async throws {
        var organizations = try loadOrganizationsIfNeeded()

        if let index = organizations.firstIndex(where: { $0.id == organization.id }) {
            organizations[index] = organization
        } else {
            organizations.append(organization)
        }

        try persistOrganizations(organizations)
    }

    func deleteOrganization(id: UUID) async throws {
        var organizations = try loadOrganizationsIfNeeded()
        organizations.removeAll { $0.id == id }
        try persistOrganizations(organizations)
    }

    func replaceOrganizations(_ organizations: [Organization]) async throws {
        try persistOrganizations(organizations)
    }

    func upsert(party: DocumentParty, role: Organization.Role) async throws {
        guard party.isEmpty == false else { return }

        var organizations = try loadOrganizationsIfNeeded()
        let incomingBankAccounts = Self.makeBankAccounts(from: party)
        let incoming = Organization(
            party: party,
            role: role,
            bankAccounts: incomingBankAccounts,
            defaultBankAccountID: incomingBankAccounts.first?.id
        )

        if let index = organizations.firstIndex(where: { $0.matchingKey == incoming.matchingKey }) {
            var existing = organizations[index]
            existing.party = Self.updatedParty(
                existing: existing,
                incoming: party,
                role: role
            )
            existing.role = Self.mergedRole(
                existing: existing.role,
                incoming: role
            )
            existing.bankAccounts = Self.mergedBankAccounts(
                existing: existing.normalizedBankAccounts,
                incoming: incomingBankAccounts
            )
            existing.defaultBankAccountID = Self.defaultBankAccountID(
                existingID: existing.defaultBankAccountID,
                accounts: existing.bankAccounts
            )
            existing.updatedAt = Date()
            organizations[index] = existing
        } else if Self.shouldInsertOrganization(role: role) {
            organizations.append(incoming)
        }

        try persistOrganizations(organizations)
    }
}

// MARK: - Private Helpers

private extension FileOrganizationsRepository {
    func loadOrganizationsIfNeeded() throws -> [Organization] {
        if let cachedOrganizations {
            return cachedOrganizations
        }

        let organizations = try store.loadOrganizations()
        cachedOrganizations = organizations
        return organizations
    }

    func persistOrganizations(_ organizations: [Organization]) throws {
        try store.saveOrganizations(organizations)
        cachedOrganizations = organizations
    }

    nonisolated static func makeBankAccounts(from party: DocumentParty) -> [OrganizationBankAccount] {
        let account = OrganizationBankAccount(
            bankName: party.bankName,
            bankAccount: party.bankAccount,
            bankCode: party.bankCode,
            isDefault: true
        )

        return account.isEmpty ? [] : [account]
    }

    nonisolated static func shouldInsertOrganization(role: Organization.Role) -> Bool {
        switch role {
        case .seller:
            return false
        case .buyer, .mixed:
            return true
        }
    }

    nonisolated static func updatedParty(
        existing: Organization,
        incoming: DocumentParty,
        role: Organization.Role
    ) -> DocumentParty {
        if role == .seller && (existing.role == .seller || existing.isDefault) {
            return existing.party
        }

        return incoming
    }

    nonisolated static func mergedRole(
        existing: Organization.Role,
        incoming: Organization.Role
    ) -> Organization.Role {
        if existing == incoming {
            return existing
        }

        return .mixed
    }

    nonisolated static func defaultBankAccountID(
        existingID: UUID?,
        accounts: [OrganizationBankAccount]
    ) -> UUID? {
        if let existingID,
           accounts.contains(where: { $0.id == existingID }) {
            return existingID
        }

        return accounts.first(where: \.isDefault)?.id ?? accounts.first?.id
    }

    nonisolated static func mergedBankAccounts(
        existing: [OrganizationBankAccount],
        incoming: [OrganizationBankAccount]
    ) -> [OrganizationBankAccount] {
        var result = existing

        for account in incoming {
            guard account.isEmpty == false else { continue }

            if result.contains(where: { Self.isSameBankAccount($0, account) }) == false {
                result.append(account)
            }
        }

        return result
    }

    nonisolated static func isSameBankAccount(
        _ lhs: OrganizationBankAccount,
        _ rhs: OrganizationBankAccount
    ) -> Bool {
        let lhsAccount = lhs.bankAccount.filter(\.isNumber)
        let rhsAccount = rhs.bankAccount.filter(\.isNumber)
        let lhsCode = lhs.bankCode.filter(\.isNumber)
        let rhsCode = rhs.bankCode.filter(\.isNumber)

        if lhsAccount.isEmpty == false || rhsAccount.isEmpty == false {
            return lhsAccount == rhsAccount && lhsCode == rhsCode
        }

        return lhs.bankName.normalizedOrganizationText == rhs.bankName.normalizedOrganizationText &&
            lhsCode == rhsCode
    }
}

private extension String {
    nonisolated var normalizedOrganizationText: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}
