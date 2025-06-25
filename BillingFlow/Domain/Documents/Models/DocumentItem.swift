import Foundation

struct DocumentItem: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var title: String
    var quantity: Decimal
    var unit: String
    var price: Decimal
    var vatRate: Decimal?

    var subtotal: Decimal {
        amount - vatAmount
    }

    var vatAmount: Decimal {
        guard let vatRate, vatRate > 0 else { return 0 }
        return amount * vatRate / (100 + vatRate)
    }

    var amount: Decimal {
        quantity * price
    }

    var isValid: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false &&
        quantity > 0 &&
        amount > 0
    }

    init(
        id: UUID = UUID(),
        title: String = "",
        quantity: Decimal = 1,
        unit: String = "шт",
        price: Decimal = 0,
        vatRate: Decimal? = nil
    ) {
        self.id = id
        self.title = title
        self.quantity = quantity
        self.unit = unit
        self.price = price
        self.vatRate = vatRate
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case quantity
        case unit
        case price
        case vatRate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        quantity = try container.decode(Decimal.self, forKey: .quantity)
        unit = try container.decode(String.self, forKey: .unit)
        price = try container.decode(Decimal.self, forKey: .price)
        vatRate = try container.decodeIfPresent(Decimal.self, forKey: .vatRate)
    }
}
