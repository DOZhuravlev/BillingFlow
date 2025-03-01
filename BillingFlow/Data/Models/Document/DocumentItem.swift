import Foundation

struct DocumentItem: Identifiable, Codable, Hashable, Sendable {

    var id: UUID
    var title: String
    var quantity: Decimal
    var unit: String
    var price: Decimal

    var amount: Decimal {
        quantity * price
    }

    var isValid: Bool {
        title.isEmpty == false &&
        quantity > 0 &&
        price >= 0
    }

    init(
        id: UUID = UUID(),
        title: String = "",
        quantity: Decimal = 1,
        unit: String = "шт",
        price: Decimal = 0
    ) {
        self.id = id
        self.title = title
        self.quantity = quantity
        self.unit = unit
        self.price = price
    }
}
