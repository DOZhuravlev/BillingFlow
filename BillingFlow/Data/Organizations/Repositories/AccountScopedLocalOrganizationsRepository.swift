import Foundation

actor AccountScopedLocalOrganizationsRepository: LocalOrganizationsRepositoryProtocol {
    private let scopeProvider: AccountDataScopeProvider
    private var repositories: [String: FileOrganizationsRepository] = [:]

    init(scopeProvider: AccountDataScopeProvider) {
        self.scopeProvider = scopeProvider
    }

    func fetchOrganizations() async throws -> [Organization] {
        try await repository().fetchOrganizations()
    }

    func save(organization: Organization) async throws {
        try await repository().save(organization: organization)
    }

    func deleteOrganization(id: UUID) async throws {
        try await repository().deleteOrganization(id: id)
    }

    func upsert(party: DocumentParty, role: Organization.Role) async throws {
        try await repository().upsert(party: party, role: role)
    }

    func replaceOrganizations(_ organizations: [Organization]) async throws {
        try await repository().replaceOrganizations(organizations)
    }

    private func repository() async throws -> FileOrganizationsRepository {
        let scope = try await scopeProvider.currentScope()
        if let repository = repositories[scope.cacheKey] {
            return repository
        }
        let repository = FileOrganizationsRepository(
            store: LocalOrganizationsStore(directoryURL: scope.directoryURL)
        )
        repositories[scope.cacheKey] = repository
        return repository
    }
}
