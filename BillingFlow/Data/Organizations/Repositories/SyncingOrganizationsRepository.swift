import Foundation

actor SyncingOrganizationsRepository: OrganizationsRepositoryProtocol {
    private let localRepository: LocalOrganizationsRepositoryProtocol
    private let remoteService: RemoteOrganizationsServiceProtocol
    private let scopeProvider: AccountDataScopeProvider
    private let didChange: @MainActor @Sendable () -> Void

    private var cachedStates: [String: OrganizationsSyncState] = [:]
    private var syncStateStores: [String: OrganizationsSyncStateStore] = [:]
    private var synchronizationTask: Task<Bool, Never>?

    init(
        localRepository: LocalOrganizationsRepositoryProtocol,
        remoteService: RemoteOrganizationsServiceProtocol,
        scopeProvider: AccountDataScopeProvider,
        didChange: @escaping @MainActor @Sendable () -> Void = { }
    ) {
        self.localRepository = localRepository
        self.remoteService = remoteService
        self.scopeProvider = scopeProvider
        self.didChange = didChange
    }

    func fetchOrganizations() async throws -> [Organization] {
        await synchronize()
        return try await localRepository.fetchOrganizations()
    }

    func save(organization: Organization) async throws {
        try await localRepository.save(organization: organization)
        await didChange()
        try await recordPendingUpserts([organization.id])
        await synchronize()
    }

    func deleteOrganization(id: UUID) async throws {
        try await localRepository.deleteOrganization(id: id)
        await didChange()
        try await recordPendingDelete(id)
        await synchronize()
    }

    func upsert(party: DocumentParty, role: Organization.Role) async throws {
        let before = try await localRepository.fetchOrganizations()
        let beforeByID = Dictionary(uniqueKeysWithValues: before.map { ($0.id, $0) })
        try await localRepository.upsert(party: party, role: role)
        let after = try await localRepository.fetchOrganizations()
        let changedIDs = Set(after.compactMap { organization in
            beforeByID[organization.id] == organization ? nil : organization.id
        })
        if changedIDs.isEmpty == false {
            await didChange()
        }
        try await recordPendingUpserts(changedIDs)
        await synchronize()
    }

    func synchronize() async {
        _ = await synchronizeReportingResult()
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

private extension SyncingOrganizationsRepository {
    func performSynchronizationReportingResult() async -> Bool {
        do {
            try await performSynchronization()
            return true
        } catch {
#if DEBUG
            print("[OrganizationsSync] Failed:", error)
#endif
            return false
        }
    }

    func performSynchronization() async throws {
        let scope = try await scopeProvider.currentScope()
        guard let userID = scope.userID else { return }

        var state = try syncState(for: scope)
        let remoteDTOs = try await remoteService.fetchOrganizations()
        let remoteOrganizations = try remoteDTOs.map(OrganizationRemoteMapper.makeOrganization)
        let remoteRevisions = revisionMap(remoteDTOs)

        if state.ownerUserID == nil {
            state.ownerUserID = userID
            let local = try await localRepository.fetchOrganizations()
            let remoteIDs = Set(remoteOrganizations.map(\.id))
            let localOnly = local.filter { remoteIDs.contains($0.id) == false }
            state.pendingUpserts.formUnion(localOnly.map(\.id))
            state.revisions = remoteRevisions

            var merged = Dictionary(uniqueKeysWithValues: remoteOrganizations.map { ($0.id, $0) })
            for organization in localOnly {
                merged[organization.id] = organization
            }
            try await replaceLocalIfNeeded(Array(merged.values))
            try saveState(state, for: scope)
        } else if state.ownerUserID != userID {
            state = OrganizationsSyncState(
                ownerUserID: userID,
                revisions: revisionMap(remoteDTOs)
            )
            try await replaceLocalIfNeeded(remoteOrganizations)
            try saveState(state, for: scope)
        }

        var localOrganizations = try await localRepository.fetchOrganizations()
        let remoteIDs = Set(remoteOrganizations.map(\.id))
        let unsyncedLocalIDs = localOrganizations
            .map(\.id)
            .filter { state.revisions[$0] == nil && remoteIDs.contains($0) == false }
        state.pendingUpserts.formUnion(unsyncedLocalIDs)
        try saveState(state, for: scope)

        for id in Array(state.pendingDeletes) {
            do {
                try await remoteService.deleteOrganization(id: id)
            } catch APIError.server(let statusCode, _) where statusCode == 404 {
                // A missing remote record already represents the requested state.
            }
            state.pendingDeletes.remove(id)
            state.revisions.removeValue(forKey: id)
            try saveState(state, for: scope)
        }

        localOrganizations = try await localRepository.fetchOrganizations()
        let localByID = Dictionary(uniqueKeysWithValues: localOrganizations.map { ($0.id, $0) })
        for id in Array(state.pendingUpserts) {
            guard let organization = localByID[id] else {
                state.pendingUpserts.remove(id)
                continue
            }
            let savedDTO = try await remoteService.saveOrganization(
                organization,
                revision: remoteRevisions[id] ?? state.revisions[id] ?? 0
            )
            state.revisions[id] = savedDTO.revision
            state.pendingUpserts.remove(id)
            try saveState(state, for: scope)
        }

        let finalDTOs = try await remoteService.fetchOrganizations()
        let finalOrganizations = try finalDTOs.map(OrganizationRemoteMapper.makeOrganization)
        try await replaceLocalIfNeeded(finalOrganizations)
        state.revisions = revisionMap(finalDTOs)
        try saveState(state, for: scope)
    }

    func recordPendingUpserts(_ ids: Set<UUID>) async throws {
        guard ids.isEmpty == false,
              let scope = try? await scopeProvider.currentScope(),
              let userID = scope.userID else { return }
        var state = try stateForUser(userID, scope: scope)
        state.pendingUpserts.formUnion(ids)
        state.pendingDeletes.subtract(ids)
        try saveState(state, for: scope)
    }

    func recordPendingDelete(_ id: UUID) async throws {
        guard let scope = try? await scopeProvider.currentScope(),
              let userID = scope.userID else { return }
        var state = try stateForUser(userID, scope: scope)
        state.pendingUpserts.remove(id)
        state.pendingDeletes.insert(id)
        try saveState(state, for: scope)
    }

    func stateForUser(_ userID: String, scope: AccountDataScope) throws -> OrganizationsSyncState {
        var state = try syncState(for: scope)
        if let ownerUserID = state.ownerUserID, ownerUserID != userID {
            state = OrganizationsSyncState(ownerUserID: userID)
        } else if state.ownerUserID == nil {
            state.ownerUserID = userID
        }
        return state
    }

    func syncState(for scope: AccountDataScope) throws -> OrganizationsSyncState {
        if let cachedState = cachedStates[scope.cacheKey] {
            return cachedState
        }
        let state = try syncStateStore(for: scope).load()
        cachedStates[scope.cacheKey] = state
        return state
    }

    func saveState(_ state: OrganizationsSyncState, for scope: AccountDataScope) throws {
        try syncStateStore(for: scope).save(state)
        cachedStates[scope.cacheKey] = state
    }

    func syncStateStore(for scope: AccountDataScope) -> OrganizationsSyncStateStore {
        if let store = syncStateStores[scope.cacheKey] {
            return store
        }
        let store = OrganizationsSyncStateStore(directoryURL: scope.directoryURL)
        syncStateStores[scope.cacheKey] = store
        return store
    }

    func revisionMap(_ items: [OrganizationRemoteDTO]) -> [UUID: Int64] {
        Dictionary(uniqueKeysWithValues: items.compactMap { item in
            guard let id = UUID(uuidString: item.id) else { return nil }
            return (id, item.revision)
        })
    }

    func replaceLocalIfNeeded(_ organizations: [Organization]) async throws {
        let sortedOrganizations = organizations.sorted { $0.updatedAt > $1.updatedAt }
        let current = try await localRepository.fetchOrganizations()
        guard current != sortedOrganizations else { return }
        try await localRepository.replaceOrganizations(sortedOrganizations)
        await didChange()
    }
}
