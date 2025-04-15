import Foundation

enum AppDependenciesFactory {
    static func make() -> AppDependencies {

        // MARK: - Document Data Dependencies
        let filesDocumentsRepository = FileDocumentsRepository()
        let documentsRepository = InMemoryDocumentsRepository()
        let organizationsRepository = FileOrganizationsRepository()
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
            tabBarVisibilityStore: tabBarVisibilityStore,
            documentEventsStore: documentEventsStore,
            documentFactory: documentFactory,
            documentValidator: documentValidator,
            documentHTMLRenderer: documentHTMLRenderer,
            pdfGenerator: pdfGenerator
        )
    }
}
