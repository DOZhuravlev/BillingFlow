import Foundation

actor SyncingDealsRepository: DealsRepositoryProtocol {
    private let localRepository: LocalDealsRepositoryProtocol
    private let remoteService: RemoteDealsServiceProtocol
    private let scopeProvider: AccountDataScopeProvider
    private let didChange: @MainActor @Sendable () -> Void

    private var states: [String: DealsSyncState] = [:]
    private var stores: [String: DealsSyncStateStore] = [:]
    private var scheduledSyncTask: Task<Void, Never>?
    private var synchronizationTask: Task<Bool, Never>?

    init(
        localRepository: LocalDealsRepositoryProtocol,
        remoteService: RemoteDealsServiceProtocol,
        scopeProvider: AccountDataScopeProvider,
        didChange: @escaping @MainActor @Sendable () -> Void = { }
    ) {
        self.localRepository = localRepository
        self.remoteService = remoteService
        self.scopeProvider = scopeProvider
        self.didChange = didChange
    }

    func fetchDeals() async throws -> [Deal] {
        _ = await synchronizeReportingResult()
        return try await localRepository.fetchDeals()
    }

    func fetchDeal(id: UUID) async throws -> Deal? {
        try await localRepository.fetchDeal(id: id)
    }

    func save(deal: Deal) async throws {
        try await localRepository.save(deal: deal)
        try await recordUpsert(deal.id)
        await didChange()
        scheduleSynchronization()
    }

    func deleteDeal(id: UUID) async throws {
        try await localRepository.deleteDeal(id: id)
        try await recordDelete(id)
        await didChange()
        scheduleSynchronization(delay: 0)
    }

    func synchronizeReportingResult() async -> Bool {
        if let synchronizationTask {
            return await synchronizationTask.value
        }

        let task = Task { [weak self] in
            await self?.performSynchronizationReportingResult() ?? false
        }
        synchronizationTask = task
        let result = await task.value
        synchronizationTask = nil
        return result
    }
}

private extension SyncingDealsRepository {
    func performSynchronizationReportingResult() async -> Bool {
        do {
            try await synchronizeNow()
            return true
        } catch {
#if DEBUG
            print("[DealsSync] Failed:", error)
#endif
            return false
        }
    }

    func scheduleSynchronization(delay: UInt64 = 700_000_000) {
        scheduledSyncTask?.cancel()
        scheduledSyncTask = Task { [weak self] in
            if delay > 0 { try? await Task.sleep(nanoseconds: delay) }
            guard Task.isCancelled == false else { return }
            _ = await self?.synchronizeReportingResult()
        }
    }

    func synchronizeNow() async throws {
        let scope = try await scopeProvider.currentScope()
        guard scope.userID != nil else { return }
        var state = try state(for: scope)
        let remoteDTOs = try await remoteService.fetchDeals()
        let remoteDeals = try remoteDTOs.map(DealRemoteMapper.makeDeal)
        let remoteRevisions = revisionMap(remoteDTOs)

        if state.revisions.isEmpty && state.pendingUpserts.isEmpty && state.pendingDeletes.isEmpty {
            let local = try await localRepository.fetchDeals()
            let remoteIDs = Set(remoteDeals.map(\.id))
            let localOnly = local.filter { remoteIDs.contains($0.id) == false }
            state.pendingUpserts.formUnion(localOnly.map(\.id))
            state.revisions = remoteRevisions

            var merged = Dictionary(uniqueKeysWithValues: remoteDeals.map { ($0.id, $0) })
            for deal in localOnly {
                merged[deal.id] = deal
            }
            try await replaceLocalIfNeeded(Array(merged.values))
            try save(state, for: scope)
        }

        let local = try await localRepository.fetchDeals()
        let remoteIDs = Set(remoteDeals.map(\.id))
        state.pendingUpserts.formUnion(
            local.map(\.id).filter { state.revisions[$0] == nil && !remoteIDs.contains($0) }
        )
        try save(state, for: scope)

        for id in Array(state.pendingDeletes) {
            do { try await remoteService.deleteDeal(id: id) }
            catch APIError.server(let code, _) where code == 404 { }
            state.pendingDeletes.remove(id)
            state.revisions.removeValue(forKey: id)
            try save(state, for: scope)
        }

        let localByID = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })
        for id in Array(state.pendingUpserts) {
            guard let deal = localByID[id] else {
                state.pendingUpserts.remove(id)
                continue
            }
            let saved = try await remoteService.saveDeal(
                deal,
                revision: remoteRevisions[id] ?? state.revisions[id] ?? 0
            )
            state.revisions[id] = saved.revision
            state.pendingUpserts.remove(id)
            try save(state, for: scope)
        }

        let finalDTOs = try await remoteService.fetchDeals()
        try await replaceLocalIfNeeded(try finalDTOs.map(DealRemoteMapper.makeDeal))
        state.revisions = revisionMap(finalDTOs)
        try save(state, for: scope)
    }

    func recordUpsert(_ id: UUID) async throws {
        let scope = try await scopeProvider.currentScope()
        guard scope.userID != nil else { return }
        var state = try state(for: scope)
        state.pendingUpserts.insert(id)
        state.pendingDeletes.remove(id)
        try save(state, for: scope)
    }

    func recordDelete(_ id: UUID) async throws {
        let scope = try await scopeProvider.currentScope()
        guard scope.userID != nil else { return }
        var state = try state(for: scope)
        state.pendingUpserts.remove(id)
        state.pendingDeletes.insert(id)
        try save(state, for: scope)
    }

    func state(for scope: AccountDataScope) throws -> DealsSyncState {
        if let state = states[scope.cacheKey] { return state }
        let state = try store(for: scope).load()
        states[scope.cacheKey] = state
        return state
    }

    func save(_ state: DealsSyncState, for scope: AccountDataScope) throws {
        try store(for: scope).save(state)
        states[scope.cacheKey] = state
    }

    func store(for scope: AccountDataScope) -> DealsSyncStateStore {
        if let store = stores[scope.cacheKey] { return store }
        let store = DealsSyncStateStore(directoryURL: scope.directoryURL)
        stores[scope.cacheKey] = store
        return store
    }

    func revisionMap(_ items: [DealRemoteDTO]) -> [UUID: Int64] {
        Dictionary(uniqueKeysWithValues: items.compactMap { dto in
            UUID(uuidString: dto.id).map { ($0, dto.revision) }
        })
    }

    func replaceLocalIfNeeded(_ deals: [Deal]) async throws {
        let sorted = deals.sorted { $0.updatedAt > $1.updatedAt }
        let current = try await localRepository.fetchDeals().sorted { $0.updatedAt > $1.updatedAt }
        guard current != sorted else { return }
        try await localRepository.replaceDeals(sorted)
        await didChange()
    }
}
