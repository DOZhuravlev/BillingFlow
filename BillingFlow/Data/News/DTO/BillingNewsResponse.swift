import Foundation

struct BillingNewsResponse: Decodable {
    let items: [BillingNewsDTO]
}

struct BillingNewsDTO: Decodable {
    let id: String
    let title: String
    let body: String
    let actionURL: String?
    let isPublished: Bool
    let updatedAt: String
}
