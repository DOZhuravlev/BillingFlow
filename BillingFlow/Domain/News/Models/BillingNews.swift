import Foundation

struct BillingNews: Identifiable, Equatable {
    let id: UUID
    let title: String
    let body: String
    let actionURL: URL?
    let updatedAt: Date?
}
