import SwiftUI

struct RootView: UIViewControllerRepresentable {

    // MARK: - Document Data Dependencies

    private let documentsRepository: DocumentsRepositoryProtocol
    private let documentFactory: DocumentFactory
    private let documentValidator: DocumentValidator

    // MARK: - Preview Dependencies

    private let documentHTMLRenderer: DocumentHTMLRenderer
    private let pdfGenerator: PDFGenerator

    // MARK: - Initialization

    init(
        documentsRepository: DocumentsRepositoryProtocol,
        documentFactory: DocumentFactory,
        documentValidator: DocumentValidator,
        documentHTMLRenderer: DocumentHTMLRenderer,
        pdfGenerator: PDFGenerator
    ) {
        self.documentsRepository = documentsRepository
        self.documentFactory = documentFactory
        self.documentValidator = documentValidator
        self.documentHTMLRenderer = documentHTMLRenderer
        self.pdfGenerator = pdfGenerator
    }

    // MARK: - Root Navigation Setup

    func makeUIViewController(context: Context) -> UINavigationController {
        let navigationController = UINavigationController()

        let router = DocumentsRouter(
            navigationController: navigationController,
            documentsRepository: documentsRepository,
            documentFactory: documentFactory,
            documentValidator: documentValidator,
            documentHTMLRenderer: documentHTMLRenderer,
            pdfGenerator: pdfGenerator
        )

        let viewModel = DocumentsListViewModel(
            router: router,
            documentsRepository: documentsRepository
        )

        router.onDocumentsDidChange = { [weak viewModel] in
            viewModel?.handleDocumentsDidChange()
        }

        let view = DocumentsScreen(viewModel: viewModel)
        let rootViewController = HostingController(
            rootView: view,
            navigationTitle: "Документы"
        )

        navigationController.viewControllers = [rootViewController]

        return navigationController
    }

    // MARK: - UIKit Update Cycle

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var router: DocumentsRouter?
    }
}
