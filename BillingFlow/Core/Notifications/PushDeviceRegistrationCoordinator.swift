import Combine
import Foundation
import UIKit

@MainActor
final class PushDeviceRegistrationCoordinator {
    private let service: RemotePushDeviceServiceProtocol
    private let userDefaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()

    init(
        service: RemotePushDeviceServiceProtocol,
        userDefaults: UserDefaults = .standard
    ) {
        self.service = service
        self.userDefaults = userDefaults
        observeRemoteNotificationToken()
        observeFCMToken()
    }

    func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    func registerStoredTokenIfPossible() async {
        if let fcmToken = userDefaults.string(forKey: Key.fcmToken) {
            await registerToken(fcmToken, provider: "fcm")
            return
        }
        if let apnsToken = userDefaults.string(forKey: Key.apnsToken) {
            await registerToken(apnsToken, provider: "apns")
        }
    }

    func unregisterCurrentDevice() async {
        do {
            try await service.deleteDevice(id: deviceID)
        } catch {
            return
        }
    }
}

private extension PushDeviceRegistrationCoordinator {
    enum Key {
        static let deviceID = "billing.push.device-id"
        static let apnsToken = "billing.push.apns-token"
        static let fcmToken = "billing.push.fcm-token"
    }

    var deviceID: String {
        if let existingID = userDefaults.string(forKey: Key.deviceID) {
            return existingID
        }
        let newID = UUID().uuidString.lowercased()
        userDefaults.set(newID, forKey: Key.deviceID)
        return newID
    }

    func observeRemoteNotificationToken() {
        NotificationCenter.default.publisher(for: .billingDidRegisterForRemoteNotifications)
            .compactMap { $0.object as? String }
            .sink { [weak self] token in
                Task { @MainActor [weak self] in
                    self?.userDefaults.set(token, forKey: Key.apnsToken)
                    if self?.userDefaults.string(forKey: Key.fcmToken) == nil {
                        await self?.registerToken(token, provider: "apns")
                    }
                }
            }
            .store(in: &cancellables)
    }

    func observeFCMToken() {
        NotificationCenter.default.publisher(for: .billingDidReceiveFCMToken)
            .compactMap { $0.object as? String }
            .sink { [weak self] token in
                Task { @MainActor [weak self] in
                    self?.userDefaults.set(token, forKey: Key.fcmToken)
                    await self?.registerToken(token, provider: "fcm")
                }
            }
            .store(in: &cancellables)
    }

    func registerToken(_ token: String, provider: String) async {
        do {
            try await service.registerDevice(
                PushDeviceRegistration(
                    id: deviceID,
                    provider: provider,
                    token: token,
                    platform: "ios",
                    environment: Self.pushEnvironment,
                    appVersion: Self.appVersion,
                    buildNumber: Self.buildNumber,
                    locale: Locale.current.identifier,
                    timeZone: TimeZone.current.identifier,
                    enabled: true
                )
            )
        } catch {
            return
        }
    }

    static var pushEnvironment: String {
        #if DEBUG
        return "sandbox"
        #else
        return "production"
        #endif
    }

    static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    static var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
}
