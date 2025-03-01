import Foundation

struct DocumentTotals: Codable, Hashable, Sendable {

    let subtotal: Decimal
    let total: Decimal
    let itemCount: Int

    static let empty = DocumentTotals(
        subtotal: 0,
        total: 0,
        itemCount: 0
    )

    init(
        subtotal: Decimal,
        total: Decimal,
        itemCount: Int
    ) {
        self.subtotal = subtotal
        self.total = total
        self.itemCount = itemCount
    }

    init(items: [DocumentItem]) {
        let subtotal = items.reduce(Decimal.zero) { partialResult, item in
            partialResult + item.amount
        }

        self.init(
            subtotal: subtotal,
            total: subtotal,
            itemCount: items.count
        )
    }
}
