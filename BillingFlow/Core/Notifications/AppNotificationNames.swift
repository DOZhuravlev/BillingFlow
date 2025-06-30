import Foundation

extension Notification.Name {
    static let billingDidRegisterForRemoteNotifications = Notification.Name("billing.didRegisterForRemoteNotifications")
    static let billingDidFailToRegisterForRemoteNotifications = Notification.Name("billing.didFailToRegisterForRemoteNotifications")
    static let billingDidReceiveFCMToken = Notification.Name("billing.didReceiveFCMToken")
}
