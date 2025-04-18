import Foundation

actor InMemoryDocumentsRepository: DocumentsRepositoryProtocol {

    // MARK: - Properties

    private var documents: [BusinessDocument]

    // MARK: - Initialization

    init(documents: [BusinessDocument]? = nil) {
        self.documents = documents ?? []
    }

    init(documents: [BusinessDocument]) {
        self.documents = documents
    }

    // MARK: - Fetching Documents

    func fetchDocuments() async throws -> [BusinessDocument] {
        documents.sorted(by: { $0.date > $1.date })
    }

    func fetchDocument(id: UUID) async throws -> BusinessDocument? {
        documents.first(where: { $0.id == id })
    }

    // MARK: - Mutating Documents

    func save(document: BusinessDocument) async throws {
        if let existingIndex = documents.firstIndex(where: { $0.id == document.id }) {
            documents[existingIndex] = document
            return
        }

        documents.append(document)
    }

    func deleteDocument(id: UUID) async throws {
        documents.removeAll(where: { $0.id == id })
    }
}
