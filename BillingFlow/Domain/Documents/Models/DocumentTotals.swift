import Foundation

struct DocumentTotals: Codable, Hashable, Sendable {
    let subtotal: Decimal
    let vatAmount: Decimal
    let total: Decimal
    let itemCount: Int

    static let empty = DocumentTotals(
        subtotal: 0,
        vatAmount: 0,
        total: 0,
        itemCount: 0
    )

    init(
        subtotal: Decimal,
        vatAmount: Decimal = 0,
        total: Decimal,
        itemCount: Int
    ) {
        self.subtotal = subtotal
        self.vatAmount = vatAmount
        self.total = total
        self.itemCount = itemCount
    }

    init(items: [DocumentItem]) {
        let subtotal = items.reduce(Decimal.zero) { partialResult, item in
            partialResult + item.subtotal
        }
        let vatAmount = items.reduce(Decimal.zero) { partialResult, item in
            partialResult + item.vatAmount
        }

        self.init(
            subtotal: subtotal,
            vatAmount: vatAmount,
            total: items.reduce(Decimal.zero) { partialResult, item in
                partialResult + item.amount
            },
            itemCount: items.count
        )
    }
}
