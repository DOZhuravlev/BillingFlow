import Foundation

struct DocumentPartyDTO: Decodable, Sendable {
    let displayName: String
    let taxID: String?
    let registrationNumber: String?
    let address: String?
    let bankName: String?
    let bankAccount: String?
    let bankCode: String?
    let contactName: String?
    let phone: String?
    let email: String?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case taxID = "tax_id"
        case registrationNumber = "registration_number"
        case address
        case bankName = "bank_name"
        case bankAccount = "bank_account"
        case bankCode = "bank_code"
        case contactName = "contact_name"
        case phone
        case email
    }
}
