import Foundation

actor FileOrganizationsRepository: OrganizationsRepositoryProtocol {

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
            existing.party = party
            existing.role = existing.role == role ? role : .mixed
            existing.bankAccounts = Self.mergedBankAccounts(
                existing: existing.normalizedBankAccounts,
                incoming: incomingBankAccounts
            )
            existing.defaultBankAccountID = existing.defaultBankAccountID ?? existing.bankAccounts.first?.id
            existing.updatedAt = Date()
            organizations[index] = existing
        } else {
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

    static func makeBankAccounts(from party: DocumentParty) -> [OrganizationBankAccount] {
        let account = OrganizationBankAccount(
            bankName: party.bankName,
            bankAccount: party.bankAccount,
            bankCode: party.bankCode,
            isDefault: true
        )

        return account.isEmpty ? [] : [account]
    }

    static func mergedBankAccounts(
        existing: [OrganizationBankAccount],
        incoming: [OrganizationBankAccount]
    ) -> [OrganizationBankAccount] {
        var result = existing

        for account in incoming {
            if result.contains(where: { $0.bankAccount == account.bankAccount && $0.bankCode == account.bankCode }) == false {
                result.append(account)
            }
        }

        return result
    }
}
