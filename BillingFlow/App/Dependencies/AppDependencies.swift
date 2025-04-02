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
