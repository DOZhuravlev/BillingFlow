import Foundation

struct DocumentParty: Codable, Hashable, Sendable {

    var displayName: String
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
}
