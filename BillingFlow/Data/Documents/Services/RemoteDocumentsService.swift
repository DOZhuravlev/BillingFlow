import Foundation

protocol RemoteDocumentsServiceProtocol: Sendable {
    func fetchDocuments() async throws -> [DocumentRemoteDTO]
    func saveDocument(_ document: BusinessDocument, revision: Int64) async throws -> DocumentRemoteDTO
    func deleteDocument(id: UUID) async throws
}

nonisolated struct RemoteDocumentsService: RemoteDocumentsServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) { self.apiClient = apiClient }

    func fetchDocuments() async throws -> [DocumentRemoteDTO] {
        let response: DocumentsRemoteResponse = try await apiClient.request(
            APIEndpoint(path: "/v1/billing/documents"), body: nil
        )
        return response.items
    }

    func saveDocument(_ document: BusinessDocument, revision: Int64) async throws -> DocumentRemoteDTO {
        try await apiClient.request(
            APIEndpoint(path: "/v1/billing/documents/\(document.id.uuidString.lowercased())", method: .put),
            body: DocumentRemoteMapper.makeUpsertDTO(from: document, revision: revision)
        )
    }

    func deleteDocument(id: UUID) async throws {
        let response: DeleteDocumentRemoteResponse = try await apiClient.request(
            APIEndpoint(path: "/v1/billing/documents/\(id.uuidString.lowercased())", method: .delete), body: nil
        )
        guard response.ok else { throw APIError.invalidResponse }
    }
}
