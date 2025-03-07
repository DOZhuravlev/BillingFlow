import Foundation

// MARK: - Document Item DTO

struct DocumentItemDTO: Decodable, Sendable {

    // MARK: - Properties

    let id: String
    let title: String
    let quantity: String
    let unit: String
    let price: String
}

// MARK: - Domain Mapping

extension DocumentItemDTO {
    func toDomain() -> DocumentItem? {
        guard
            let itemID = UUID(uuidString: id),
            let itemQuantity = Self.parseDecimal(quantity),
            let itemPrice = Self.parseDecimal(price)
        else {
            return nil
        }

        return DocumentItem(
            id: itemID,
            title: title,
            quantity: itemQuantity,
            unit: unit,
            price: itemPrice
        )
    }

    // MARK: - Decimal Parsing

    private static func parseDecimal(_ value: String) -> Decimal? {
        Decimal(string: value) ?? Decimal(string: value.replacingOccurrences(of: ",", with: "."))
    }
}
