import Foundation

enum DealDocumentKind: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case contract
    case invoice
    case act
    case universalTransferDocument
    case invoiceFacture
    case paymentReceipt

    var id: String { rawValue }

    var title: String {
        switch self {
        case .contract: return "Договор"
        case .invoice: return "Счет"
        case .act: return "Акт"
        case .universalTransferDocument: return "УПД"
        case .invoiceFacture: return "Счет-фактура"
        case .paymentReceipt: return "Подтверждение оплаты"
        }
    }

    var iconName: String {
        switch self {
        case .contract: return "doc.text.fill"
        case .invoice: return "banknote.fill"
        case .act: return "checkmark.seal.fill"
        case .universalTransferDocument: return "doc.on.doc.fill"
        case .invoiceFacture: return "doc.text.magnifyingglass"
        case .paymentReceipt: return "checkmark.circle.fill"
        }
    }

    var supportedDocumentType: DocumentType? {
        switch self {
        case .invoice: return .invoice
        case .act: return .act
        case .invoiceFacture: return .deliveryNote
        case .contract, .universalTransferDocument, .paymentReceipt: return nil
        }
    }

    static func kind(for type: DocumentType) -> DealDocumentKind {
        switch type {
        case .invoice: return .invoice
        case .act: return .act
        case .deliveryNote: return .invoiceFacture
        }
    }
}
