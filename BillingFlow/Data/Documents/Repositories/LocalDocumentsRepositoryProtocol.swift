import Foundation

protocol LocalDocumentsRepositoryProtocol: DocumentsRepositoryProtocol {
    func replaceDocuments(_ documents: [BusinessDocument]) async throws
}

extension AccountScopedDocumentsRepository: LocalDocumentsRepositoryProtocol { }
