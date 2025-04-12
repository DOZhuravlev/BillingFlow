import Foundation

enum DocumentTypeFilter: CaseIterable, Identifiable, Equatable {
    case all
    case invoices
    case acts
    case deliveryNotes

    var id: Self { self }

    var title: String {
        switch self {
        case .all:
            return "Все"
        case .invoices:
            return "Счета"
        case .acts:
            return "Акты"
        case .deliveryNotes:
            return "Счета-фактуры"
        }
    }

    var systemImage: String? {
        switch self {
        case .all:
            return "square.grid.2x2"
        case .invoices:
            return "doc.text"
        case .acts:
            return "checkmark.seal"
        case .deliveryNotes:
            return "doc.text.magnifyingglass"
        }
    }

    func matches(_ document: BusinessDocument) -> Bool {
        switch self {
        case .all:
            return true
        case .invoices:
            return document.type == .invoice
        case .acts:
            return document.type == .act
        case .deliveryNotes:
            return document.type == .deliveryNote
        }
    }
}
