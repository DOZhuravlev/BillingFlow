import SwiftUI

@main
struct BillingFlowApp: App {

    // MARK: - Document Data Dependencies

    let documentsRepository = InMemoryDocumentsRepository()
    let filesDocumentsRepository = FileDocumentsRepository()
    let documentFactory = DocumentFactory()
    let documentValidator = DocumentValidator()

    // MARK: - Preview Dependencies

    let documentHTMLRenderer = DocumentHTMLRenderer()
    let pdfGenerator = PDFGenerator()

    // MARK: - App Entry

    var body: some Scene {
        WindowGroup {
            RootView(
                documentsRepository: documentsRepository,
                documentFactory: documentFactory,
                documentValidator: documentValidator,
                documentHTMLRenderer: documentHTMLRenderer,
                pdfGenerator: pdfGenerator
            )
        }
    }
}
