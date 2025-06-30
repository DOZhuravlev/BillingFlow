import Foundation

nonisolated struct DocumentParty: Codable, Hashable, Sendable {
    var displayName: String
    var fullName: String
    var shortName: String
    var taxID: String
    var registrationNumber: String
    var address: String
    var bankName: String
    var bankAccount: String
    var bankCode: String
    var contactName: String
    var phone: String
    var email: String

    var isEmpty: Bool {
        displayName.isEmpty &&
        fullName.isEmpty &&
        shortName.isEmpty &&
        taxID.isEmpty &&
        registrationNumber.isEmpty &&
        address.isEmpty &&
        bankName.isEmpty &&
        bankAccount.isEmpty &&
        bankCode.isEmpty &&
        contactName.isEmpty &&
        phone.isEmpty &&
        email.isEmpty
    }

    init(
        displayName: String = "",
        fullName: String = "",
        shortName: String = "",
        taxID: String = "",
        registrationNumber: String = "",
        address: String = "",
        bankName: String = "",
        bankAccount: String = "",
        bankCode: String = "",
        contactName: String = "",
        phone: String = "",
        email: String = ""
    ) {
        self.displayName = displayName
        self.fullName = fullName
        self.shortName = shortName
        self.taxID = taxID
        self.registrationNumber = registrationNumber
        self.address = address
        self.bankName = bankName
        self.bankAccount = bankAccount
        self.bankCode = bankCode
        self.contactName = contactName
        self.phone = phone
        self.email = email
    }

    enum CodingKeys: String, CodingKey {
        case displayName
        case fullName
        case shortName
        case taxID
        case registrationNumber
        case address
        case bankName
        case bankAccount
        case bankCode
        case contactName
        case phone
        case email
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? ""
        fullName = try container.decodeIfPresent(String.self, forKey: .fullName) ?? ""
        shortName = try container.decodeIfPresent(String.self, forKey: .shortName) ?? ""
        taxID = try container.decodeIfPresent(String.self, forKey: .taxID) ?? ""
        registrationNumber = try container.decodeIfPresent(String.self, forKey: .registrationNumber) ?? ""
        address = try container.decodeIfPresent(String.self, forKey: .address) ?? ""
        bankName = try container.decodeIfPresent(String.self, forKey: .bankName) ?? ""
        bankAccount = try container.decodeIfPresent(String.self, forKey: .bankAccount) ?? ""
        bankCode = try container.decodeIfPresent(String.self, forKey: .bankCode) ?? ""
        contactName = try container.decodeIfPresent(String.self, forKey: .contactName) ?? ""
        phone = try container.decodeIfPresent(String.self, forKey: .phone) ?? ""
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
    }
}
