import Foundation

struct PaginationDTO: Decodable, Sendable {
    let nextCursor: String?
    let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case nextCursor = "next_cursor"
        case hasMore = "has_more"
    }
}
