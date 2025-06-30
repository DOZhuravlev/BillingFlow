import Foundation

nonisolated struct OrganizationBankAccount: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var bankName: String
    var bankAccount: String
    var bankCode: String
    var correspondentAccount: String
    var isDefault: Bool

    init(
        id: UUID = UUID(),
        bankName: String = "",
        bankAccount: String = "",
        bankCode: String = "",
        correspondentAccount: String = "",
        isDefault: Bool = false
    ) {
        self.id = id
        self.bankName = bankName
        self.bankAccount = bankAccount
        self.bankCode = bankCode
        self.correspondentAccount = correspondentAccount
        self.isDefault = isDefault
    }

    var displayTitle: String {
        bankName.isEmpty ? "Банк не указан" : bankName
    }

    var displaySubtitle: String {
        let accountText = bankAccount.isEmpty ? "Счет не указан" : bankAccount
        let bankCodeText = bankCode.isEmpty ? nil : "БИК \(bankCode)"
        return [accountText, bankCodeText].compactMap { $0 }.joined(separator: " · ")
    }

    var isEmpty: Bool {
        bankName.isEmpty &&
        bankAccount.isEmpty &&
        bankCode.isEmpty &&
        correspondentAccount.isEmpty
    }

    func apply(to party: DocumentParty) -> DocumentParty {
        var nextParty = party
        nextParty.bankName = bankName
        nextParty.bankAccount = bankAccount
        nextParty.bankCode = bankCode
        return nextParty
    }
}
