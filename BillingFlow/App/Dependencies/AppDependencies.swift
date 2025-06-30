import Foundation

struct AppDependencies {
    let documentsRepository: DocumentsRepositoryProtocol
    let dealsRepository: DealsRepositoryProtocol
    let organizationsRepository: OrganizationsRepositoryProtocol
    let organizationSearchService: OrganizationSearchServiceProtocol
    let authController: AuthController
    let syncCoordinator: AppSyncCoordinator
    let notificationPreferences: NotificationPreferences
    let notificationCoordinator: AppNotificationCoordinator
    let appRouteStore: AppRouteStore
    let tabBarVisibilityStore: TabBarVisibilityStore
    let documentEventsStore: DocumentEventsStore
    let dealEventsStore: DealEventsStore
    let organizationEventsStore: OrganizationEventsStore
    let documentFactory: DocumentFactory
    let documentValidator: DocumentValidator
    let documentHTMLRenderer: DocumentHTMLRenderer
    let pdfGenerator: PDFGenerator

    init(
        documentsRepository: DocumentsRepositoryProtocol,
        dealsRepository: DealsRepositoryProtocol,
        organizationsRepository: OrganizationsRepositoryProtocol,
        organizationSearchService: OrganizationSearchServiceProtocol,
        authController: AuthController,
        syncCoordinator: AppSyncCoordinator,
        notificationPreferences: NotificationPreferences,
        notificationCoordinator: AppNotificationCoordinator,
        appRouteStore: AppRouteStore,
        tabBarVisibilityStore: TabBarVisibilityStore,
        documentEventsStore: DocumentEventsStore,
        dealEventsStore: DealEventsStore,
        organizationEventsStore: OrganizationEventsStore,
        documentFactory: DocumentFactory,
        documentValidator: DocumentValidator,
        documentHTMLRenderer: DocumentHTMLRenderer,
        pdfGenerator: PDFGenerator
    ) {
        self.documentsRepository = documentsRepository
        self.dealsRepository = dealsRepository
        self.organizationsRepository = organizationsRepository
        self.organizationSearchService = organizationSearchService
        self.authController = authController
        self.syncCoordinator = syncCoordinator
        self.notificationPreferences = notificationPreferences
        self.notificationCoordinator = notificationCoordinator
        self.appRouteStore = appRouteStore
        self.tabBarVisibilityStore = tabBarVisibilityStore
        self.documentEventsStore = documentEventsStore
        self.dealEventsStore = dealEventsStore
        self.organizationEventsStore = organizationEventsStore
        self.documentFactory = documentFactory
        self.documentValidator = documentValidator
        self.documentHTMLRenderer = documentHTMLRenderer
        self.pdfGenerator = pdfGenerator
    }
}
