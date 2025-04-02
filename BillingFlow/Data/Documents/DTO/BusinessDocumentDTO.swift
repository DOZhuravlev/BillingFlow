import Foundation

struct BusinessDocumentDTO: Decodable, Sendable {
    let id: String
    let type: String
    let number: String
    let date: String
    let seller: DocumentPartyDTO
    let buyer: DocumentPartyDTO
    let items: [DocumentItemDTO]
    let notes: String?
    let currencyCode: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case number
        case date
        case seller
        case buyer
        case items
        case notes
        case currencyCode = "currency_code"
        case status
    }
}
