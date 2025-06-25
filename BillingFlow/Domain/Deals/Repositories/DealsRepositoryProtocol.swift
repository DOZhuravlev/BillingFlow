import Foundation

protocol DealsRepositoryProtocol: Sendable {
    func fetchDeals() async throws -> [Deal]
    func fetchDeal(id: UUID) async throws -> Deal?
    func save(deal: Deal) async throws
    func deleteDeal(id: UUID) async throws
}
