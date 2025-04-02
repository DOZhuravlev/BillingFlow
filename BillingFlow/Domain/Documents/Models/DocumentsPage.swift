import Foundation

struct DocumentsPage: Sendable {
    let documents: [BusinessDocument]
    let nextCursor: String?
    let hasMore: Bool
}
