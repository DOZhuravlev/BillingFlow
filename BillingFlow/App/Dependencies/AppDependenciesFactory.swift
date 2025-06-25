import Foundation

enum AppDependenciesFactory {
    static func make() -> AppDependencies {

        // MARK: - Document Data Dependencies
        let documentsRepository = FileDocumentsRepository()
        let dealsRepository = FileDealsRepository()
        let organizationsRepository = FileOrganizationsRepository()
        let apiClient = APIClient(baseURL: URL(string: "https://api.bukinarena.site")!)
        let organizationSearchService = RemoteOrganizationSearchService(apiClient: apiClient)
        let appRouteStore = AppRouteStore()
        let tabBarVisibilityStore = TabBarVisibilityStore()
        let documentEventsStore = DocumentEventsStore()
        let dealEventsStore = DealEventsStore()
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
            appRouteStore: appRouteStore,
            tabBarVisibilityStore: tabBarVisibilityStore,
            documentEventsStore: documentEventsStore,
            dealEventsStore: dealEventsStore,
            documentFactory: documentFactory,
            documentValidator: documentValidator,
            documentHTMLRenderer: documentHTMLRenderer,
            pdfGenerator: pdfGenerator
        )
    }
}
