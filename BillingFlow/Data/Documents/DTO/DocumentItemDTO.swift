import Foundation

struct DocumentItemDTO: Decodable, Sendable {
    let id: String
    let title: String
    let quantity: String
    let unit: String
    let price: String
}
