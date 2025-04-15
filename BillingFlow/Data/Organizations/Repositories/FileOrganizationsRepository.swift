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
        let incoming = Organization(party: party, role: role)

        if let index = organizations.firstIndex(where: { $0.matchingKey == incoming.matchingKey }) {
            var existing = organizations[index]
            existing.party = party
            existing.role = existing.role == role ? role : .mixed
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
}
