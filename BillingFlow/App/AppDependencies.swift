import Foundation

struct AppDependencies {
    let filesDocumentsRepository: FileDocumentsRepository
    let documentsRepository: DocumentsRepositoryProtocol
    let documentFactory: DocumentFactory
    let documentValidator: DocumentValidator
    let documentHTMLRenderer: DocumentHTMLRenderer
    let pdfGenerator: PDFGenerator

    init(
        filesDocumentsRepository: FileDocumentsRepository,
        documentsRepository: DocumentsRepositoryProtocol,
        documentFactory: DocumentFactory,
        documentValidator: DocumentValidator,
        documentHTMLRenderer: DocumentHTMLRenderer,
        pdfGenerator: PDFGenerator
    ) {
        self.filesDocumentsRepository = filesDocumentsRepository
        self.documentsRepository = documentsRepository
        self.documentFactory = documentFactory
        self.documentValidator = documentValidator
        self.documentHTMLRenderer = documentHTMLRenderer
        self.pdfGenerator = pdfGenerator
    }
}

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
