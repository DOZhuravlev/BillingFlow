import Foundation

actor AccountScopedDealsRepository: DealsRepositoryProtocol {
    private let scopeProvider: AccountDataScopeProvider
    private var repositories: [String: FileDealsRepository] = [:]

    init(scopeProvider: AccountDataScopeProvider) {
        self.scopeProvider = scopeProvider
    }

    func fetchDeals() async throws -> [Deal] {
        try await repository().fetchDeals()
    }

    func fetchDeal(id: UUID) async throws -> Deal? {
        try await repository().fetchDeal(id: id)
    }

    func save(deal: Deal) async throws {
        try await repository().save(deal: deal)
    }

    func deleteDeal(id: UUID) async throws {
        try await repository().deleteDeal(id: id)
    }

    func replaceDeals(_ deals: [Deal]) async throws {
        try await repository().replaceDeals(deals)
    }

    private func repository() async throws -> FileDealsRepository {
        let scope = try await scopeProvider.currentScope()
        if let repository = repositories[scope.cacheKey] {
            return repository
        }
        let repository = FileDealsRepository(
            store: LocalDealsStore(directoryURL: scope.directoryURL)
        )
        repositories[scope.cacheKey] = repository
        return repository
    }
}
