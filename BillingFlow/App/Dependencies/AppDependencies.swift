import Foundation

struct AppDependencies {
    let filesDocumentsRepository: FileDocumentsRepository
    let documentsRepository: DocumentsRepositoryProtocol
    let organizationsRepository: OrganizationsRepositoryProtocol
    let organizationSearchService: OrganizationSearchServiceProtocol
    let appRouteStore: AppRouteStore
    let tabBarVisibilityStore: TabBarVisibilityStore
    let documentEventsStore: DocumentEventsStore
    let documentFactory: DocumentFactory
    let documentValidator: DocumentValidator
    let documentHTMLRenderer: DocumentHTMLRenderer
    let pdfGenerator: PDFGenerator

    init(
        filesDocumentsRepository: FileDocumentsRepository,
        documentsRepository: DocumentsRepositoryProtocol,
        organizationsRepository: OrganizationsRepositoryProtocol,
        organizationSearchService: OrganizationSearchServiceProtocol,
        appRouteStore: AppRouteStore,
        tabBarVisibilityStore: TabBarVisibilityStore,
        documentEventsStore: DocumentEventsStore,
        documentFactory: DocumentFactory,
        documentValidator: DocumentValidator,
        documentHTMLRenderer: DocumentHTMLRenderer,
        pdfGenerator: PDFGenerator
    ) {
        self.filesDocumentsRepository = filesDocumentsRepository
        self.documentsRepository = documentsRepository
        self.organizationsRepository = organizationsRepository
        self.organizationSearchService = organizationSearchService
        self.appRouteStore = appRouteStore
        self.tabBarVisibilityStore = tabBarVisibilityStore
        self.documentEventsStore = documentEventsStore
        self.documentFactory = documentFactory
        self.documentValidator = documentValidator
        self.documentHTMLRenderer = documentHTMLRenderer
        self.pdfGenerator = pdfGenerator
    }
}
