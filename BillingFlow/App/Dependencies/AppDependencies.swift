import Foundation

struct AppDependencies {
    let documentsRepository: DocumentsRepositoryProtocol
    let dealsRepository: DealsRepositoryProtocol
    let organizationsRepository: OrganizationsRepositoryProtocol
    let organizationSearchService: OrganizationSearchServiceProtocol
    let appRouteStore: AppRouteStore
    let tabBarVisibilityStore: TabBarVisibilityStore
    let documentEventsStore: DocumentEventsStore
    let dealEventsStore: DealEventsStore
    let documentFactory: DocumentFactory
    let documentValidator: DocumentValidator
    let documentHTMLRenderer: DocumentHTMLRenderer
    let pdfGenerator: PDFGenerator

    init(
        documentsRepository: DocumentsRepositoryProtocol,
        dealsRepository: DealsRepositoryProtocol,
        organizationsRepository: OrganizationsRepositoryProtocol,
        organizationSearchService: OrganizationSearchServiceProtocol,
        appRouteStore: AppRouteStore,
        tabBarVisibilityStore: TabBarVisibilityStore,
        documentEventsStore: DocumentEventsStore,
        dealEventsStore: DealEventsStore,
        documentFactory: DocumentFactory,
        documentValidator: DocumentValidator,
        documentHTMLRenderer: DocumentHTMLRenderer,
        pdfGenerator: PDFGenerator
    ) {
        self.documentsRepository = documentsRepository
        self.dealsRepository = dealsRepository
        self.organizationsRepository = organizationsRepository
        self.organizationSearchService = organizationSearchService
        self.appRouteStore = appRouteStore
        self.tabBarVisibilityStore = tabBarVisibilityStore
        self.documentEventsStore = documentEventsStore
        self.dealEventsStore = dealEventsStore
        self.documentFactory = documentFactory
        self.documentValidator = documentValidator
        self.documentHTMLRenderer = documentHTMLRenderer
        self.pdfGenerator = pdfGenerator
    }
}
