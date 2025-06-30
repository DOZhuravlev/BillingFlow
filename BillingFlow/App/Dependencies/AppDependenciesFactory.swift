import Foundation

enum AppDependenciesFactory {
    static func make() -> AppDependencies {

        // MARK: - Document Data Dependencies
        let baseURL = URL(string: "https://api.bukinarena.site")!
        let keychain = KeychainStore(service: "com.my.BillingFlow.auth")
        let authSession = AuthSession(baseURL: baseURL, keychain: keychain)
        let publicAPIClient = APIClient(baseURL: baseURL)
        let apiClient = APIClient(baseURL: baseURL, authorizationProvider: authSession)
        let scopeProvider = AccountDataScopeProvider(authSession: authSession)
        let localDocumentsRepository = AccountScopedDocumentsRepository(scopeProvider: scopeProvider)
        let localDealsRepository = AccountScopedDealsRepository(scopeProvider: scopeProvider)
        let organizationEventsStore = OrganizationEventsStore()
        let documentEventsStore = DocumentEventsStore()
        let dealEventsStore = DealEventsStore()
        let localOrganizationsRepository = AccountScopedLocalOrganizationsRepository(
            scopeProvider: scopeProvider
        )
        let remoteOrganizationsService = RemoteOrganizationsService(apiClient: apiClient)
        let remoteDocumentsService = RemoteDocumentsService(apiClient: apiClient)
        let remoteDealsService = RemoteDealsService(apiClient: apiClient)
        let remotePushDeviceService = RemotePushDeviceService(apiClient: apiClient)
        let documentsRepository = SyncingDocumentsRepository(
            localRepository: localDocumentsRepository,
            remoteService: remoteDocumentsService,
            scopeProvider: scopeProvider,
            didChange: {
                documentEventsStore.sendDocumentsDidChange()
            }
        )
        let dealsRepository = SyncingDealsRepository(
            localRepository: localDealsRepository,
            remoteService: remoteDealsService,
            scopeProvider: scopeProvider,
            didChange: {
                dealEventsStore.sendDealsDidChange()
            }
        )
        let organizationsRepository = SyncingOrganizationsRepository(
            localRepository: localOrganizationsRepository,
            remoteService: remoteOrganizationsService,
            scopeProvider: scopeProvider,
            didChange: {
                organizationEventsStore.sendOrganizationsDidChange()
            }
        )
        let syncCoordinator = AppSyncCoordinator(
            organizationsRepository: organizationsRepository,
            documentsRepository: documentsRepository,
            dealsRepository: dealsRepository,
            documentEventsStore: documentEventsStore,
            dealEventsStore: dealEventsStore,
            organizationEventsStore: organizationEventsStore
        )
        let notificationPreferences = NotificationPreferences()
        let pushRegistrationCoordinator = PushDeviceRegistrationCoordinator(
            service: remotePushDeviceService
        )
        let notificationCoordinator = AppNotificationCoordinator(
            documentsRepository: documentsRepository,
            documentEventsStore: documentEventsStore,
            preferences: notificationPreferences,
            localNotificationService: LocalNotificationService(),
            pushRegistrationCoordinator: pushRegistrationCoordinator
        )
        let authService = RemoteAuthService(apiClient: publicAPIClient, authSession: authSession)
        let authController = AuthController(
            authService: authService,
            authSession: authSession,
            didAuthenticate: {
                await syncCoordinator.accountDidChange()
                await notificationCoordinator.accountDidChange()
            },
            willLogout: {
                await notificationCoordinator.willLogout()
            },
            didLogout: {
                await syncCoordinator.accountDidChange()
            }
        )
        let organizationSearchService = RemoteOrganizationSearchService(apiClient: apiClient)
        let appRouteStore = AppRouteStore()
        let tabBarVisibilityStore = TabBarVisibilityStore()
        let documentFactory = DocumentFactory()
        let documentValidator = DocumentValidator()

        // MARK: - Preview Dependencies

        let documentHTMLRenderer = DocumentHTMLRenderer()
        let pdfGenerator = PDFGenerator()

        return AppDependencies(
            documentsRepository: documentsRepository,
            dealsRepository: dealsRepository,
            organizationsRepository: organizationsRepository,
            organizationSearchService: organizationSearchService,
            authController: authController,
            syncCoordinator: syncCoordinator,
            notificationPreferences: notificationPreferences,
            notificationCoordinator: notificationCoordinator,
            appRouteStore: appRouteStore,
            tabBarVisibilityStore: tabBarVisibilityStore,
            documentEventsStore: documentEventsStore,
            dealEventsStore: dealEventsStore,
            organizationEventsStore: organizationEventsStore,
            documentFactory: documentFactory,
            documentValidator: documentValidator,
            documentHTMLRenderer: documentHTMLRenderer,
            pdfGenerator: pdfGenerator
        )
    }
}
