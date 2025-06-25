import Foundation

enum DealStatus: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case draft
    case preparingDocuments
    case invoiceIssued
    case awaitingPayment
    case overdue
    case partiallyPaid
    case paid
    case needsClosingDocuments
    case closingDocumentsSent
    case closed
    case cancelled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .draft: return "Черновик"
        case .preparingDocuments: return "Подготовка документов"
        case .invoiceIssued: return "Счет выставлен"
        case .awaitingPayment: return "Ожидает оплаты"
        case .overdue: return "Просрочено"
        case .partiallyPaid: return "Частично оплачено"
        case .paid: return "Оплачено"
        case .needsClosingDocuments: return "Нужен акт или УПД"
        case .closingDocumentsSent: return "Закрывающие отправлены"
        case .closed: return "Закрыто"
        case .cancelled: return "Отменено"
        }
    }

    var progress: Double {
        switch self {
        case .draft: return 0.08
        case .preparingDocuments: return 0.18
        case .invoiceIssued: return 0.35
        case .awaitingPayment, .overdue: return 0.5
        case .partiallyPaid: return 0.65
        case .paid: return 0.78
        case .needsClosingDocuments: return 0.84
        case .closingDocumentsSent: return 0.92
        case .closed: return 1
        case .cancelled: return 0
        }
    }
}
