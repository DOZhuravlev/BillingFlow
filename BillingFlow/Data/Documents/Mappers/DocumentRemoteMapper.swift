import Foundation

nonisolated enum DocumentRemoteMapper {
    static func makeDocument(from dto: DocumentRemoteDTO) throws -> BusinessDocument {
        guard let id = UUID(uuidString: dto.id),
              let type = DocumentType(rawValue: dto.type),
              let status = DocumentStatus(rawValue: dto.status) else {
            throw MappingError.invalidValue
        }
        return BusinessDocument(
            id: id,
            type: type,
            number: dto.number,
            date: try date(dto.date),
            seller: dto.seller,
            buyer: dto.buyer,
            items: dto.items,
            notes: dto.notes,
            currencyCode: dto.currencyCode,
            status: status,
            paidAt: try dto.paidAt.map(date),
            paymentReminderDate: try dto.paymentReminderDate.map(date),
            dealID: dto.dealID.flatMap(UUID.init(uuidString:)),
            draftStepRawValue: dto.draftStepRawValue,
            updatedAt: try date(dto.updatedAt)
        )
    }

    static func makeUpsertDTO(from document: BusinessDocument, revision: Int64) -> DocumentUpsertRemoteDTO {
        DocumentUpsertRemoteDTO(
            type: document.type.rawValue,
            number: document.number,
            date: string(document.date),
            seller: document.seller,
            buyer: document.buyer,
            items: document.items,
            notes: document.notes,
            currencyCode: document.currencyCode,
            status: document.status.rawValue,
            paidAt: document.paidAt.map(string),
            paymentReminderDate: document.paymentReminderDate.map(string),
            dealID: document.dealID?.uuidString.lowercased(),
            draftStepRawValue: document.draftStepRawValue,
            revision: revision
        )
    }
}

private extension DocumentRemoteMapper {
    enum MappingError: Error { case invalidValue, invalidDate }

    nonisolated static func date(_ value: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: value) else { throw MappingError.invalidDate }
        return date
    }

    nonisolated static func string(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}
