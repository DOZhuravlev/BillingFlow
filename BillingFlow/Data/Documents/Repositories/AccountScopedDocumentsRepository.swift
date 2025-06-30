import Foundation

actor AccountScopedDocumentsRepository: DocumentsRepositoryProtocol {
    private let scopeProvider: AccountDataScopeProvider
    private var repositories: [String: FileDocumentsRepository] = [:]

    init(scopeProvider: AccountDataScopeProvider) {
        self.scopeProvider = scopeProvider
    }

    func fetchDocuments() async throws -> [BusinessDocument] {
        try await repository().fetchDocuments()
    }

    func fetchDocument(id: UUID) async throws -> BusinessDocument? {
        try await repository().fetchDocument(id: id)
    }

    func save(document: BusinessDocument) async throws {
        try await repository().save(document: document)
    }

    func deleteDocument(id: UUID) async throws {
        try await repository().deleteDocument(id: id)
    }

    func replaceDocuments(_ documents: [BusinessDocument]) async throws {
        try await repository().replaceDocuments(documents)
    }

    private func repository() async throws -> FileDocumentsRepository {
        let scope = try await scopeProvider.currentScope()
        if let repository = repositories[scope.cacheKey] {
            return repository
        }
        let repository = FileDocumentsRepository(
            store: LocalDocumentsStore(directoryURL: scope.directoryURL)
        )
        repositories[scope.cacheKey] = repository
        return repository
    }
}
