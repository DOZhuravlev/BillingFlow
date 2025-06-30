import Foundation

protocol LocalDealsRepositoryProtocol: DealsRepositoryProtocol {
    func replaceDeals(_ deals: [Deal]) async throws
}

extension AccountScopedDealsRepository: LocalDealsRepositoryProtocol { }
