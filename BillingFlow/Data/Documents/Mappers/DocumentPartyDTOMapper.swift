import Foundation

struct DocumentPartyDTOMapper {

    func map(_ dto: DocumentPartyDTO) -> DocumentParty {
        DocumentParty(
            displayName: cleaned(dto.displayName),
            fullName: cleaned(dto.fullName),
            shortName: cleaned(dto.shortName),
            taxID: cleaned(dto.taxID),
            registrationNumber: cleaned(dto.registrationNumber),
            address: cleaned(dto.address),
            bankName: cleaned(dto.bankName),
            bankAccount: cleaned(dto.bankAccount),
            bankCode: cleaned(dto.bankCode),
            contactName: cleaned(dto.contactName),
            phone: cleaned(dto.phone),
            email: cleaned(dto.email)
        )
    }

    private func cleaned(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func cleaned(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
