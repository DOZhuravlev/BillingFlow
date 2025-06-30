import Foundation

actor SyncingDocumentsRepository: DocumentsRepositoryProtocol {
    private let localRepository: LocalDocumentsRepositoryProtocol
    private let remoteService: RemoteDocumentsServiceProtocol
    private let scopeProvider: AccountDataScopeProvider
    private let didChange: @MainActor @Sendable () -> Void

    private var states: [String: DocumentsSyncState] = [:]
    private var stores: [String: DocumentsSyncStateStore] = [:]
    private var scheduledSyncTask: Task<Void, Never>?
    private var synchronizationTask: Task<Bool, Never>?

    init(
        localRepository: LocalDocumentsRepositoryProtocol,
        remoteService: RemoteDocumentsServiceProtocol,
        scopeProvider: AccountDataScopeProvider,
        didChange: @escaping @MainActor @Sendable () -> Void = { }
    ) {
        self.localRepository = localRepository
        self.remoteService = remoteService
        self.scopeProvider = scopeProvider
        self.didChange = didChange
    }

    func fetchDocuments() async throws -> [BusinessDocument] {
        _ = await synchronizeReportingResult()
        return try await localRepository.fetchDocuments()
    }

    func fetchDocument(id: UUID) async throws -> BusinessDocument? {
        try await localRepository.fetchDocument(id: id)
    }

    func save(document: BusinessDocument) async throws {
        try await localRepository.save(document: document)
        try await recordUpsert(document.id)
        await didChange()
        scheduleSynchronization()
    }

    func deleteDocument(id: UUID) async throws {
        try await localRepository.deleteDocument(id: id)
        try await recordDelete(id)
        await didChange()
        scheduleSynchronization(delay: 0)
    }

    func flushPendingChanges() async {
        scheduledSyncTask?.cancel()
        scheduledSyncTask = nil
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

private extension SyncingDocumentsRepository {
    func performSynchronizationReportingResult() async -> Bool {
        do {
            try await synchronizeNow()
            return true
        } catch {
#if DEBUG
            print("[DocumentsSync] Failed:", error)
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
        let remoteDTOs = try await remoteService.fetchDocuments()
        let remoteDocuments = try remoteDTOs.map(DocumentRemoteMapper.makeDocument)
        let remoteRevisions = revisionMap(remoteDTOs)

        if state.revisions.isEmpty && state.pendingUpserts.isEmpty && state.pendingDeletes.isEmpty {
            let local = try await localRepository.fetchDocuments()
            let remoteIDs = Set(remoteDocuments.map(\.id))
            let localOnly = local.filter { remoteIDs.contains($0.id) == false }
            state.pendingUpserts.formUnion(localOnly.map(\.id))
            state.revisions = remoteRevisions

            var merged = Dictionary(uniqueKeysWithValues: remoteDocuments.map { ($0.id, $0) })
            for document in localOnly {
                merged[document.id] = document
            }
            try await replaceLocalIfNeeded(Array(merged.values))
            try save(state, for: scope)
        }

        let local = try await localRepository.fetchDocuments()
        let remoteIDs = Set(remoteDocuments.map(\.id))
        state.pendingUpserts.formUnion(local.map(\.id).filter { state.revisions[$0] == nil && !remoteIDs.contains($0) })
        try save(state, for: scope)

        for id in Array(state.pendingDeletes) {
            do { try await remoteService.deleteDocument(id: id) }
            catch APIError.server(let code, _) where code == 404 { }
            state.pendingDeletes.remove(id)
            state.revisions.removeValue(forKey: id)
            try save(state, for: scope)
        }

        let localByID = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })
        for id in Array(state.pendingUpserts) {
            guard let document = localByID[id] else { state.pendingUpserts.remove(id); continue }
            let saved = try await remoteService.saveDocument(document, revision: remoteRevisions[id] ?? state.revisions[id] ?? 0)
            state.revisions[id] = saved.revision
            state.pendingUpserts.remove(id)
            try save(state, for: scope)
        }

        let finalDTOs = try await remoteService.fetchDocuments()
        try await replaceLocalIfNeeded(try finalDTOs.map(DocumentRemoteMapper.makeDocument))
        state.revisions = revisionMap(finalDTOs)
        try save(state, for: scope)
    }

    func recordUpsert(_ id: UUID) async throws {
        let scope = try await scopeProvider.currentScope()
        guard scope.userID != nil else { return }
        var state = try state(for: scope)
        state.pendingUpserts.insert(id); state.pendingDeletes.remove(id)
        try save(state, for: scope)
    }

    func recordDelete(_ id: UUID) async throws {
        let scope = try await scopeProvider.currentScope()
        guard scope.userID != nil else { return }
        var state = try state(for: scope)
        state.pendingUpserts.remove(id); state.pendingDeletes.insert(id)
        try save(state, for: scope)
    }

    func state(for scope: AccountDataScope) throws -> DocumentsSyncState {
        if let state = states[scope.cacheKey] { return state }
        let state = try store(for: scope).load(); states[scope.cacheKey] = state; return state
    }

    func save(_ state: DocumentsSyncState, for scope: AccountDataScope) throws {
        try store(for: scope).save(state); states[scope.cacheKey] = state
    }

    func store(for scope: AccountDataScope) -> DocumentsSyncStateStore {
        if let store = stores[scope.cacheKey] { return store }
        let store = DocumentsSyncStateStore(directoryURL: scope.directoryURL); stores[scope.cacheKey] = store; return store
    }

    func revisionMap(_ items: [DocumentRemoteDTO]) -> [UUID: Int64] {
        Dictionary(uniqueKeysWithValues: items.compactMap { dto in UUID(uuidString: dto.id).map { ($0, dto.revision) } })
    }

    func replaceLocalIfNeeded(_ documents: [BusinessDocument]) async throws {
        let sorted = documents.sorted { ($0.updatedAt ?? $0.date) > ($1.updatedAt ?? $1.date) }
        let current = try await localRepository.fetchDocuments().sorted { ($0.updatedAt ?? $0.date) > ($1.updatedAt ?? $1.date) }
        guard current != sorted else { return }
        try await localRepository.replaceDocuments(sorted)
        await didChange()
    }
}
