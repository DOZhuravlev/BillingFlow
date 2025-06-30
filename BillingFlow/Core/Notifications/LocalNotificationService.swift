import Foundation
import UserNotifications

protocol LocalNotificationServiceProtocol: Sendable {
    func requestAuthorization() async -> Bool
    func notificationSettings() async -> UNNotificationSettings
    func reconcilePaymentReminders(for documents: [BusinessDocument], isEnabled: Bool) async
    func cancelAllPaymentReminders() async
}

struct LocalNotificationService: LocalNotificationServiceProtocol {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func notificationSettings() async -> UNNotificationSettings {
        await center.notificationSettings()
    }

    func reconcilePaymentReminders(for documents: [BusinessDocument], isEnabled: Bool) async {
        guard isEnabled else {
            await cancelAllPaymentReminders()
            return
        }

        let validDocuments = documents.filter(Self.shouldScheduleReminder)
        let validIdentifiers = Set(validDocuments.map(Self.paymentReminderIdentifier))
        let pendingRequests = await center.pendingNotificationRequests()
        let staleIdentifiers = pendingRequests
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.paymentReminderIdentifierPrefix) && validIdentifiers.contains($0) == false }

        if staleIdentifiers.isEmpty == false {
            center.removePendingNotificationRequests(withIdentifiers: staleIdentifiers)
        }

        for document in validDocuments {
            await schedulePaymentReminder(for: document)
        }
    }

    func cancelAllPaymentReminders() async {
        let pendingRequests = await center.pendingNotificationRequests()
        let identifiers = pendingRequests
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.paymentReminderIdentifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

private extension LocalNotificationService {
    static let paymentReminderIdentifierPrefix = "billing.payment-reminder."

    static func paymentReminderIdentifier(for document: BusinessDocument) -> String {
        "\(paymentReminderIdentifierPrefix)\(document.id.uuidString.lowercased())"
    }

    static func shouldScheduleReminder(for document: BusinessDocument) -> Bool {
        guard document.type == .invoice,
              document.status != .draft,
              document.paidAt == nil,
              let reminderDate = document.paymentReminderDate else {
            return false
        }
        return reminderDate > Date()
    }

    func schedulePaymentReminder(for document: BusinessDocument) async {
        guard let reminderDate = document.paymentReminderDate else { return }

        let content = UNMutableNotificationContent()
        content.title = "Проверьте оплату"
        content.body = "\(document.buyer.displayName) · \(document.number)"
        content.sound = .default
        content.userInfo = [
            "documentID": document.id.uuidString.lowercased(),
            "type": "paymentReminder"
        ]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.paymentReminderIdentifier(for: document),
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }
}
