import Foundation

// MARK: - Documents Response

struct DocumentsResponse: Decodable, Sendable {

    // MARK: - Properties

    let documents: [BusinessDocumentDTO]
    let pagination: PaginationDTO
}
