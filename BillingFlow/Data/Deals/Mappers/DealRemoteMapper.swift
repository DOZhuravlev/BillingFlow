import Foundation

nonisolated enum DealRemoteMapper {
    static func makeDeal(from dto: DealRemoteDTO) throws -> Deal {
        guard let id = UUID(uuidString: dto.id),
              let type = DealType(rawValue: dto.type),
              let amount = Decimal(string: dto.amount, locale: posixLocale) else {
            throw MappingError.invalidValue
        }
        let statusOverride: DealStatus?
        if let value = dto.statusOverride {
            guard let status = DealStatus(rawValue: value) else { throw MappingError.invalidValue }
            statusOverride = status
        } else {
            statusOverride = nil
        }
        return Deal(
            id: id,
            title: dto.title,
            type: type,
            counterparty: dto.counterparty,
            amount: amount,
            currencyCode: dto.currencyCode,
            statusOverride: statusOverride,
            dueDate: try dto.dueDate.map(date),
            reminderDate: try dto.reminderDate.map(date),
            note: dto.note,
            phone: dto.phone,
            createdAt: try date(dto.createdAt),
            updatedAt: try date(dto.updatedAt)
        )
    }

    static func makeUpsertDTO(from deal: Deal, revision: Int64) -> DealUpsertRemoteDTO {
        DealUpsertRemoteDTO(
            title: deal.title,
            type: deal.type.rawValue,
            counterparty: deal.counterparty,
            amount: NSDecimalNumber(decimal: deal.amount).stringValue,
            currencyCode: deal.currencyCode,
            statusOverride: deal.statusOverride?.rawValue,
            dueDate: deal.dueDate.map(string),
            reminderDate: deal.reminderDate.map(string),
            note: deal.note,
            phone: deal.phone,
            revision: revision
        )
    }
}

private extension DealRemoteMapper {
    enum MappingError: Error { case invalidValue, invalidDate }

    nonisolated static var posixLocale: Locale { Locale(identifier: "en_US_POSIX") }

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
