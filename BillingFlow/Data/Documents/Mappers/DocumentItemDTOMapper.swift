import Foundation

struct DocumentItemDTOMapper {

    func map(_ dto: DocumentItemDTO) -> DocumentItem? {
        guard
            let itemID = UUID(uuidString: dto.id),
            let itemQuantity = parseDecimal(dto.quantity),
            let itemPrice = parseDecimal(dto.price)
        else {
            return nil
        }

        return DocumentItem(
            id: itemID,
            title: cleaned(dto.title),
            quantity: itemQuantity,
            unit: cleaned(dto.unit),
            price: itemPrice
        )
    }

    private func cleaned(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseDecimal(_ value: String) -> Decimal? {
        let normalizedValue = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        return Decimal(string: normalizedValue)
    }
}
