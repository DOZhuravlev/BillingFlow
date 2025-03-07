import Foundation

// MARK: - Document Party DTO

struct DocumentPartyDTO: Decodable, Sendable {

    // MARK: - Properties

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

    // MARK: - Coding Keys

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

// MARK: - Domain Mapping

extension DocumentPartyDTO {
    func toDomain() -> DocumentParty {
        DocumentParty(
            displayName: cleaned(displayName),
            taxID: cleaned(taxID),
            registrationNumber: cleaned(registrationNumber),
            address: cleaned(address),
            bankName: cleaned(bankName),
            bankAccount: cleaned(bankAccount),
            bankCode: cleaned(bankCode),
            contactName: cleaned(contactName),
            phone: cleaned(phone),
            email: cleaned(email)
        )
    }

    private func cleaned(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func cleaned(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
