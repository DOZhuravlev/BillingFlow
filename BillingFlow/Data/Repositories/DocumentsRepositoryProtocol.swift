import Foundation

protocol DocumentsRepositoryProtocol: Sendable {
    func fetchDocuments() async throws -> [BusinessDocument]
    func fetchDocument(id: UUID) async throws -> BusinessDocument?
    func save(document: BusinessDocument) async throws
    func deleteDocument(id: UUID) async throws
}
