import Foundation

protocol RemoteOrganizationsServiceProtocol: Sendable {
    func fetchOrganizations() async throws -> [OrganizationRemoteDTO]
    func saveOrganization(_ organization: Organization, revision: Int64) async throws -> OrganizationRemoteDTO
    func deleteOrganization(id: UUID) async throws
}

nonisolated struct RemoteOrganizationsService: RemoteOrganizationsServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func fetchOrganizations() async throws -> [OrganizationRemoteDTO] {
        let response: OrganizationsRemoteResponse = try await apiClient.request(
            APIEndpoint(path: "/v1/billing/organizations"),
            body: nil
        )
        return response.items
    }

    func saveOrganization(_ organization: Organization, revision: Int64) async throws -> OrganizationRemoteDTO {
        try await apiClient.request(
            APIEndpoint(
                path: "/v1/billing/organizations/\(organization.id.uuidString.lowercased())",
                method: .put
            ),
            body: OrganizationRemoteMapper.makeUpsertDTO(from: organization, revision: revision)
        )
    }

    func deleteOrganization(id: UUID) async throws {
        let response: DeleteOrganizationRemoteResponse = try await apiClient.request(
            APIEndpoint(
                path: "/v1/billing/organizations/\(id.uuidString.lowercased())",
                method: .delete
            ),
            body: nil
        )
        guard response.ok else {
            throw APIError.invalidResponse
        }
    }
}
