import Foundation

struct Deal: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var title: String
    var type: DealType
    var counterparty: DocumentParty
    var amount: Decimal
    var currencyCode: String
    var statusOverride: DealStatus?
    var dueDate: Date?
    var reminderDate: Date?
    var note: String
    var phone: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "",
        type: DealType,
        counterparty: DocumentParty = DocumentParty(),
        amount: Decimal = 0,
        currencyCode: String = "RUB",
        statusOverride: DealStatus? = nil,
        dueDate: Date? = nil,
        reminderDate: Date? = nil,
        note: String = "",
        phone: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.counterparty = counterparty
        self.amount = amount
        self.currencyCode = currencyCode
        self.statusOverride = statusOverride
        self.dueDate = dueDate
        self.reminderDate = reminderDate
        self.note = note
        self.phone = phone
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func effectiveStatus(documents: [BusinessDocument], now: Date = Date()) -> DealStatus {
        if let statusOverride { return statusOverride }

        let readyDocuments = documents.filter { $0.status != .draft }
        let invoices = readyDocuments.filter { $0.type == .invoice }
        let hasClosingDocument = readyDocuments.contains { $0.type == .act || $0.type == .deliveryNote }

        if invoices.isEmpty {
            return readyDocuments.isEmpty ? .draft : .preparingDocuments
        }
        if invoices.allSatisfy({ $0.paidAt != nil }) {
            return hasClosingDocument ? .paid : .needsClosingDocuments
        }
        if let dueDate, dueDate < now {
            return .overdue
        }
        return .awaitingPayment
    }
}
