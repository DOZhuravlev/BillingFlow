import Combine
import Foundation

@MainActor
final class NotificationPreferences: ObservableObject {
    @Published private(set) var isEnabled: Bool

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if userDefaults.object(forKey: Key.isEnabled) == nil {
            self.isEnabled = true
        } else {
            self.isEnabled = userDefaults.bool(forKey: Key.isEnabled)
        }
    }

    func setEnabled(_ isEnabled: Bool) {
        self.isEnabled = isEnabled
        userDefaults.set(isEnabled, forKey: Key.isEnabled)
    }
}

private extension NotificationPreferences {
    enum Key {
        static let isEnabled = "billing.notifications.enabled"
    }
}
