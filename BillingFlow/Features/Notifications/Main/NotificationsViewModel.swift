import Combine
import Foundation

@MainActor
final class NotificationsViewModel: ObservableObject {

    // MARK: - State

    @Published private(set) var notifications: [NotificationItem]
    private let onClose: () -> Void

    // MARK: - Initialization

    init(
        notifications: [NotificationItem]? = nil,
        onClose: @escaping () -> Void = { }
    ) {
        let notifications = notifications ?? NotificationsViewModel.defaultNotifications()
        self.notifications = notifications.sorted { $0.date > $1.date }
        self.onClose = onClose
    }
}

// MARK: - Derived State

extension NotificationsViewModel {
    var unreadCount: Int {
        notifications.filter { $0.isRead == false }.count
    }

    var subtitle: String {
        guard notifications.isEmpty == false else {
            return "Новых событий пока нет"
        }

        guard unreadCount > 0 else {
            return "Все уведомления прочитаны"
        }

        return "\(unreadCount) \(unreadCount.unreadWord)"
    }
}

// MARK: - User Actions

extension NotificationsViewModel {
    func didTapClose() {
        onClose()
    }
}

private extension NotificationsViewModel {
    static func defaultNotifications() -> [NotificationItem] {
        [
            NotificationItem(
                kind: .document,
                title: "Счет сохранен",
                message: "Документ добавлен в список и доступен для предпросмотра.",
                date: Date(timeIntervalSinceNow: -1_800),
                isRead: false
            ),
            NotificationItem(
                kind: .payment,
                title: "Ожидает отправки",
                message: "Подпишите документ и отправьте его контрагенту.",
                date: Date(timeIntervalSinceNow: -7_200),
                isRead: false
            ),
            NotificationItem(
                kind: .system,
                title: "Профиль организации",
                message: "Добавьте подпись и печать, чтобы быстрее готовить документы.",
                date: Date(timeIntervalSinceNow: -86_400),
                isRead: true
            )
        ]
    }
}

private extension Int {
    var unreadWord: String {
        let lastTwoDigits = self % 100
        let lastDigit = self % 10

        if (11...14).contains(lastTwoDigits) {
            return "новых уведомлений"
        }

        switch lastDigit {
        case 1:
            return "новое уведомление"
        case 2...4:
            return "новых уведомления"
        default:
            return "новых уведомлений"
        }
    }
}
