import Foundation

struct DocumentsResponse: Decodable, Sendable {
    let documents: [BusinessDocumentDTO]
    let pagination: PaginationDTO
}
