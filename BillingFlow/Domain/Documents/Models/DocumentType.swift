import Foundation

enum DocumentType: String, CaseIterable, Codable, Hashable, Sendable {
    case invoice
    case act
    case deliveryNote

    var displayName: String {
        switch self {
        case .invoice:
            return "Счет"
        case .act:
            return "Акт"
        case .deliveryNote:
            return "Накладная"
        }
    }
}
