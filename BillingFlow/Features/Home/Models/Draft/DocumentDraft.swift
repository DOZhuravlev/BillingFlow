import Foundation

struct DocumentDraft: Identifiable, Codable, Hashable, Sendable {

    var id: UUID
    var type: DocumentType
    var number: String
    var date: Date
    var seller: DocumentParty
    var buyer: DocumentParty
    var items: [DocumentItem]
    var notes: String
    var currencyCode: String
    var sourceDocumentID: UUID?
    var paymentReminderDate: Date?
    var dealID: UUID?
    var updatedAt: Date

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
        sourceDocumentID: UUID? = nil,
        paymentReminderDate: Date? = nil,
        dealID: UUID? = nil,
        updatedAt: Date = Date()
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
        self.sourceDocumentID = sourceDocumentID
        self.paymentReminderDate = paymentReminderDate
        self.dealID = dealID
        self.updatedAt = updatedAt
    }

    func asBusinessDocument(
        status: DocumentStatus = .draft,
        draftStepRawValue: Int? = nil
    ) -> BusinessDocument {
        BusinessDocument(
            id: id,
            type: type,
            number: number,
            date: date,
            seller: seller,
            buyer: buyer,
            items: items,
            notes: notes,
            currencyCode: currencyCode,
            status: status,
            paymentReminderDate: paymentReminderDate,
            dealID: dealID,
            draftStepRawValue: draftStepRawValue,
            updatedAt: updatedAt
        )
    }
}
