import Foundation

actor FileDocumentsRepository: DocumentsRepositoryProtocol {

    // MARK: - Dependencies

    private let store: LocalDocumentsStore

    // MARK: - Properties

    private var cachedDocuments: [BusinessDocument]?

    // MARK: - Initialization

    init() {
        self.store = LocalDocumentsStore()
    }

    init(store: LocalDocumentsStore) {
        self.store = store
    }

    // MARK: - Fetching Documents

    func fetchDocuments() async throws -> [BusinessDocument] {
        let documents = try loadDocumentsIfNeeded()
        return documents.sorted(by: { $0.date > $1.date })
    }

    func fetchDocument(id: UUID) async throws -> BusinessDocument? {
        let documents = try loadDocumentsIfNeeded()
        return documents.first(where: { $0.id == id })
    }

    // MARK: - Mutating Documents

    func save(document: BusinessDocument) async throws {
        var documents = try loadDocumentsIfNeeded()

        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            documents[index] = document
        } else {
            documents.append(document)
        }

        try persistDocuments(documents)
    }

    func deleteDocument(id: UUID) async throws {
        var documents = try loadDocumentsIfNeeded()
        documents.removeAll(where: { $0.id == id })
        try persistDocuments(documents)
    }

    // MARK: - Private Helpers

    private func loadDocumentsIfNeeded() throws -> [BusinessDocument] {
        if let cachedDocuments {
            return cachedDocuments
        }

        let loadedDocuments = try store.loadDocuments()
        cachedDocuments = loadedDocuments
        return loadedDocuments
    }

    private func persistDocuments(_ documents: [BusinessDocument]) throws {
        try store.saveDocuments(documents)
        cachedDocuments = documents
    }
}
