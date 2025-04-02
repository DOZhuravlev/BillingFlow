import Foundation

enum AppDependenciesFactory {
    static func make() -> AppDependencies {

        // MARK: - Document Data Dependencies
        let filesDocumentsRepository = FileDocumentsRepository()
        let documentsRepository = InMemoryDocumentsRepository()
        let documentFactory = DocumentFactory()
        let documentValidator = DocumentValidator()

        // MARK: - Preview Dependencies

        let documentHTMLRenderer = DocumentHTMLRenderer()
        let pdfGenerator = PDFGenerator()

        return AppDependencies(
            filesDocumentsRepository: filesDocumentsRepository,
            documentsRepository: documentsRepository,
            documentFactory: documentFactory,
            documentValidator: documentValidator,
            documentHTMLRenderer: documentHTMLRenderer,
            pdfGenerator: pdfGenerator
        )
    }
}
