import Foundation

protocol OrganizationsRepositoryProtocol: Sendable {
    func fetchOrganizations() async throws -> [Organization]
    func save(organization: Organization) async throws
    func upsert(party: DocumentParty, role: Organization.Role) async throws
}
