import Combine
import Foundation
import UIKit
import UserNotifications

@MainActor
final class AppNotificationCoordinator {
    private let documentsRepository: DocumentsRepositoryProtocol
    private let documentEventsStore: DocumentEventsStore
    private let appRouteStore: AppRouteStore
    private let preferences: NotificationPreferences
    private let localNotificationService: LocalNotificationServiceProtocol
    private let pushRegistrationCoordinator: PushDeviceRegistrationCoordinator

    private var cancellables = Set<AnyCancellable>()
    private var reconcileTask: Task<Void, Never>?
    private var isStarted = false

    init(
        documentsRepository: DocumentsRepositoryProtocol,
        documentEventsStore: DocumentEventsStore,
        appRouteStore: AppRouteStore,
        preferences: NotificationPreferences,
        localNotificationService: LocalNotificationServiceProtocol,
        pushRegistrationCoordinator: PushDeviceRegistrationCoordinator
    ) {
        self.documentsRepository = documentsRepository
        self.documentEventsStore = documentEventsStore
        self.appRouteStore = appRouteStore
        self.preferences = preferences
        self.localNotificationService = localNotificationService
        self.pushRegistrationCoordinator = pushRegistrationCoordinator
    }

    func start() {
        guard isStarted == false else { return }
        isStarted = true

        documentEventsStore.documentsDidChangePublisher
            .sink { [weak self] in
                self?.scheduleReconcile()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.scheduleReconcile()
                Task { @MainActor [weak self] in
                    await self?.pushRegistrationCoordinator.registerStoredTokenIfPossible()
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .billingDidOpenNotification)
            .sink { [weak self] notification in
                guard let userInfo = notification.object as? [AnyHashable: Any] else { return }
                self?.handleNotificationOpen(userInfo: userInfo)
            }
            .store(in: &cancellables)

        scheduleReconcile()
    }

    func setNotificationsEnabled(_ isEnabled: Bool) async {
        if isEnabled {
            let isGranted = await localNotificationService.requestAuthorization()
            guard isGranted else {
                preferences.setEnabled(false)
                await localNotificationService.cancelAllPaymentReminders()
                return
            }
            preferences.setEnabled(true)
            pushRegistrationCoordinator.registerForRemoteNotifications()
            await pushRegistrationCoordinator.registerStoredTokenIfPossible()
            scheduleReconcile(immediate: true)
        } else {
            preferences.setEnabled(false)
            await localNotificationService.cancelAllPaymentReminders()
            await pushRegistrationCoordinator.unregisterCurrentDevice()
        }
    }

    func accountDidChange() async {
        await pushRegistrationCoordinator.registerStoredTokenIfPossible()
        scheduleReconcile(immediate: true)
    }

    func willLogout() async {
        await pushRegistrationCoordinator.unregisterCurrentDevice()
    }
}

private extension AppNotificationCoordinator {
    func scheduleReconcile(immediate: Bool = false) {
        reconcileTask?.cancel()
        reconcileTask = Task { [weak self] in
            if immediate == false {
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
            await self?.reconcilePaymentReminders()
        }
    }

    func reconcilePaymentReminders() async {
        do {
            let documents = try await documentsRepository.fetchDocuments()
            let shouldUseNotifications = await ensureAuthorizationIfNeeded(for: documents)
            await localNotificationService.reconcilePaymentReminders(
                for: documents,
                isEnabled: shouldUseNotifications
            )
        } catch {
            return
        }
    }

    func ensureAuthorizationIfNeeded(for documents: [BusinessDocument]) async -> Bool {
        guard preferences.isEnabled else { return false }
        guard documents.contains(where: shouldRequestNotificationPermission) else { return true }

        let settings = await localNotificationService.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            pushRegistrationCoordinator.registerForRemoteNotifications()
            await pushRegistrationCoordinator.registerStoredTokenIfPossible()
            return true
        case .notDetermined:
            let isGranted = await localNotificationService.requestAuthorization()
            preferences.setEnabled(isGranted)
            if isGranted {
                pushRegistrationCoordinator.registerForRemoteNotifications()
                await pushRegistrationCoordinator.registerStoredTokenIfPossible()
            }
            return isGranted
        case .denied:
            preferences.setEnabled(false)
            return false
        @unknown default:
            return false
        }
    }

    func shouldRequestNotificationPermission(for document: BusinessDocument) -> Bool {
        document.status != .draft &&
        document.paidAt == nil &&
        document.paymentReminderDate.map { $0 > Date() } == true
    }

    func handleNotificationOpen(userInfo: [AnyHashable: Any]) {
        guard let route = NotificationRoute(userInfo: userInfo) else { return }

        switch route.type {
        case .paymentReminder, .document:
            guard let documentID = route.documentID else { return }
            appRouteStore.openDocument(id: documentID)
        case .news:
            appRouteStore.openNews(id: route.newsID)
        case .deal:
            return
        }
    }
}
