import Foundation

enum AppDependenciesFactory {
    static func make() -> AppDependencies {

        // MARK: - Document Data Dependencies
        let filesDocumentsRepository = FileDocumentsRepository()
        let documentsRepository = InMemoryDocumentsRepository()
        let organizationsRepository = FileOrganizationsRepository()
        let apiClient = APIClient(baseURL: URL(string: "https://api.bukinarena.site")!)
        let organizationSearchService = RemoteOrganizationSearchService(apiClient: apiClient)
        let tabBarVisibilityStore = TabBarVisibilityStore()
        let documentEventsStore = DocumentEventsStore()
        let documentFactory = DocumentFactory()
        let documentValidator = DocumentValidator()

        // MARK: - Preview Dependencies

        let documentHTMLRenderer = DocumentHTMLRenderer()
        let pdfGenerator = PDFGenerator()

        return AppDependencies(
            filesDocumentsRepository: filesDocumentsRepository,
            documentsRepository: documentsRepository,
            organizationsRepository: organizationsRepository,
            organizationSearchService: organizationSearchService,
            tabBarVisibilityStore: tabBarVisibilityStore,
            documentEventsStore: documentEventsStore,
            documentFactory: documentFactory,
            documentValidator: documentValidator,
            documentHTMLRenderer: documentHTMLRenderer,
            pdfGenerator: pdfGenerator
        )
    }
}
