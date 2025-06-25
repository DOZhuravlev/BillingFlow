import Foundation

actor FileDealsRepository: DealsRepositoryProtocol {
    private let store: LocalDealsStore
    private var cache: [Deal]?

    init(store: LocalDealsStore = LocalDealsStore()) {
        self.store = store
    }

    func fetchDeals() async throws -> [Deal] {
        try load().sorted { $0.updatedAt > $1.updatedAt }
    }

    func fetchDeal(id: UUID) async throws -> Deal? {
        try load().first { $0.id == id }
    }

    func save(deal: Deal) async throws {
        var deals = try load()
        if let index = deals.firstIndex(where: { $0.id == deal.id }) {
            deals[index] = deal
        } else {
            deals.append(deal)
        }
        try persist(deals)
    }

    func deleteDeal(id: UUID) async throws {
        var deals = try load()
        deals.removeAll { $0.id == id }
        try persist(deals)
    }

    private func load() throws -> [Deal] {
        if let cache { return cache }
        let deals = try store.loadDeals()
        cache = deals
        return deals
    }

    private func persist(_ deals: [Deal]) throws {
        try store.saveDeals(deals)
        cache = deals
    }
}
