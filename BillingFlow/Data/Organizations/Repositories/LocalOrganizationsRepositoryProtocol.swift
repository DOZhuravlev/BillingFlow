import Foundation

protocol LocalOrganizationsRepositoryProtocol: Sendable {
    func fetchOrganizations() async throws -> [Organization]
    func save(organization: Organization) async throws
    func deleteOrganization(id: UUID) async throws
    func upsert(party: DocumentParty, role: Organization.Role) async throws
    func replaceOrganizations(_ organizations: [Organization]) async throws
}

extension FileOrganizationsRepository: LocalOrganizationsRepositoryProtocol { }
