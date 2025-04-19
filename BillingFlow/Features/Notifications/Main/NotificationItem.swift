import Foundation

struct NotificationItem: Identifiable, Hashable {
    enum Kind: Hashable {
        case document
        case payment
        case system

        var iconName: String {
            switch self {
            case .document:
                return "doc.text.fill"
            case .payment:
                return "creditcard.fill"
            case .system:
                return "bell.badge.fill"
            }
        }
    }

    let id: UUID
    let kind: Kind
    let title: String
    let message: String
    let date: Date
    let isRead: Bool

    init(
        id: UUID = UUID(),
        kind: Kind,
        title: String,
        message: String,
        date: Date,
        isRead: Bool
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.message = message
        self.date = date
        self.isRead = isRead
    }
}
