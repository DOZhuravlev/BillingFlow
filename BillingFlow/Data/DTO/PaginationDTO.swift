import Foundation

// MARK: - Pagination DTO

struct PaginationDTO: Decodable, Sendable {

    // MARK: - Properties

    let nextCursor: String?
    let hasMore: Bool

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case nextCursor = "next_cursor"
        case hasMore = "has_more"
    }
}
