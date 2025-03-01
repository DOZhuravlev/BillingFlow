import Foundation

struct BusinessDocument: Identifiable, Codable, Hashable, Sendable {

    var id: UUID
    var type: DocumentType
    var number: String
    var date: Date
    var seller: DocumentParty
    var buyer: DocumentParty
    var items: [DocumentItem]
    var notes: String
    var currencyCode: String
    var status: DocumentStatus

    var totals: DocumentTotals {
        DocumentTotals(items: items)
    }

    var isReady: Bool {
        number.isEmpty == false &&
        seller.isEmpty == false &&
        buyer.isEmpty == false &&
        items.isEmpty == false &&
        items.allSatisfy(\.isValid)
    }

    init(
        id: UUID = UUID(),
        type: DocumentType,
        number: String = "",
        date: Date = Date(),
        seller: DocumentParty = DocumentParty(),
        buyer: DocumentParty = DocumentParty(),
        items: [DocumentItem] = [],
        notes: String = "",
        currencyCode: String = "RUB",
        status: DocumentStatus = .draft
    ) {
        self.id = id
        self.type = type
        self.number = number
        self.date = date
        self.seller = seller
        self.buyer = buyer
        self.items = items
        self.notes = notes
        self.currencyCode = currencyCode
        self.status = status
    }
}
