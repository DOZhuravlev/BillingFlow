import Foundation

protocol RemoteDealsServiceProtocol: Sendable {
    func fetchDeals() async throws -> [DealRemoteDTO]
    func saveDeal(_ deal: Deal, revision: Int64) async throws -> DealRemoteDTO
    func deleteDeal(id: UUID) async throws
}

nonisolated struct RemoteDealsService: RemoteDealsServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) { self.apiClient = apiClient }

    func fetchDeals() async throws -> [DealRemoteDTO] {
        let response: DealsRemoteResponse = try await apiClient.request(
            APIEndpoint(path: "/v1/billing/deals"), body: nil
        )
        return response.items
    }

    func saveDeal(_ deal: Deal, revision: Int64) async throws -> DealRemoteDTO {
        try await apiClient.request(
            APIEndpoint(path: "/v1/billing/deals/\(deal.id.uuidString.lowercased())", method: .put),
            body: DealRemoteMapper.makeUpsertDTO(from: deal, revision: revision)
        )
    }

    func deleteDeal(id: UUID) async throws {
        let response: DeleteDealRemoteResponse = try await apiClient.request(
            APIEndpoint(path: "/v1/billing/deals/\(id.uuidString.lowercased())", method: .delete), body: nil
        )
        guard response.ok else { throw APIError.invalidResponse }
    }
}
