import Foundation

struct BusinessDocumentDTOMapper {

    // MARK: - Dependencies

    private let partyMapper: DocumentPartyDTOMapper
    private let itemMapper: DocumentItemDTOMapper

    // MARK: - Initialization

    init(
        partyMapper: DocumentPartyDTOMapper = DocumentPartyDTOMapper(),
        itemMapper: DocumentItemDTOMapper = DocumentItemDTOMapper()
    ) {
        self.partyMapper = partyMapper
        self.itemMapper = itemMapper
    }

    func map(_ dto: BusinessDocumentDTO) -> BusinessDocument? {
        let normalizedType = cleaned(dto.type)
        let normalizedStatus = cleaned(dto.status)
        let normalizedCurrencyCode = cleaned(dto.currencyCode).uppercased()
        let normalizedNumber = cleaned(dto.number)

        guard
            let documentID = UUID(uuidString: dto.id),
            let documentDate = parseDate(dto.date),
            normalizedCurrencyCode.isEmpty == false,
            let documentType = DocumentType(rawValue: normalizedType),
            let documentStatus = DocumentStatus(rawValue: normalizedStatus)
        else {
            return nil
        }

        let mappedItems = dto.items.compactMap { itemMapper.map($0) }

        guard mappedItems.count == dto.items.count else {
            return nil
        }

        return BusinessDocument(
            id: documentID,
            type: documentType,
            number: normalizedNumber,
            date: documentDate,
            seller: partyMapper.map(dto.seller),
            buyer: partyMapper.map(dto.buyer),
            items: mappedItems,
            notes: dto.notes ?? "",
            currencyCode: normalizedCurrencyCode,
            status: documentStatus
        )
    }

    private func cleaned(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseDate(_ value: String) -> Date? {
        parseDateWithFractionalSeconds(value) ?? parseDateWithoutFractionalSeconds(value)
    }

    private func parseDateWithFractionalSeconds(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value)
    }

    private func parseDateWithoutFractionalSeconds(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}
