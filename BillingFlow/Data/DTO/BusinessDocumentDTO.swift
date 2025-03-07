import Foundation

// MARK: - Business Document DTO

struct BusinessDocumentDTO: Decodable, Sendable {

    // MARK: - Properties

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

    // MARK: - Coding Keys

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

// MARK: - Domain Mapping

extension BusinessDocumentDTO {

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let fractionalSecondsFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    func toDomain() -> BusinessDocument? {
        let normalizedType = type.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedStatus = status.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedCurrencyCode = currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let normalizedNumber = number.trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            let documentID = UUID(uuidString: id),
            let documentDate = Self.parseDate(date),
            normalizedCurrencyCode.isEmpty == false,
            let documentType = DocumentType(rawValue: normalizedType),
            let documentStatus = DocumentStatus(rawValue: normalizedStatus)
        else {
            return nil
        }

        let mappedItems = items.compactMap { $0.toDomain() }

        guard mappedItems.count == items.count else {
            return nil
        }

        let domainDocument = BusinessDocument(
            id: documentID,
            type: documentType,
            number: normalizedNumber,
            date: documentDate,
            seller: seller.toDomain(),
            buyer: buyer.toDomain(),
            items: mappedItems,
            notes: notes ?? "",
            currencyCode: normalizedCurrencyCode,
            status: documentStatus
        )

        return domainDocument
    }

    // MARK: - Date Parsing

    private static func parseDate(_ value: String) -> Date? {
        fractionalSecondsFormatter.date(from: value) ?? isoFormatter.date(from: value)
    }
}
