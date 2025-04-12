import UIKit

@MainActor
final class DocumentsCoordinator: DocumentsCoordinatorProtocol {

    // MARK: - Navigation

    private let navigationController: UINavigationController

    // MARK: - Document Data Dependencies

    private let documentsRepository: DocumentsRepositoryProtocol
    private let documentFactory: DocumentFactory
    private let documentValidator: DocumentValidator

    // MARK: - Preview Dependencies

    private let documentHTMLRenderer: DocumentHTMLRenderer
    private let pdfGenerator: PDFGenerator

    private weak var documentsListViewModel: DocumentsListViewModel?

    // MARK: - Initialization

    init(
        navigationController: UINavigationController,
        documentsRepository: DocumentsRepositoryProtocol,
        documentFactory: DocumentFactory,
        documentValidator: DocumentValidator,
        documentHTMLRenderer: DocumentHTMLRenderer,
        pdfGenerator: PDFGenerator
    ) {
        self.navigationController = navigationController
        self.documentsRepository = documentsRepository
        self.documentFactory = documentFactory
        self.documentValidator = documentValidator
        self.documentHTMLRenderer = documentHTMLRenderer
        self.pdfGenerator = pdfGenerator
    }

    // MARK: - Start coordinator

    func start() {
        let viewModel = DocumentsListViewModel(
            coordinator: self,
            documentsRepository: documentsRepository
        )

        documentsListViewModel = viewModel

        let view = DocumentsScreen(viewModel: viewModel)

        let controller = HostingController(
            rootView: view,
            navigationTitle: "Документы"
        )

        navigationController.viewControllers = [controller]
    }

    // MARK: - Document Detail Navigation

    func showDetail(document: BusinessDocument) {
        let viewModel = DocumentDetailViewModel(
            document: document,
            coordinator: self
        )

        let view = DocumentDetailScreen(viewModel: viewModel)
        let controller = HostingController(
            rootView: view,
            navigationTitle: "Документ",
            titleDisplayMode: .never
        )

        navigationController.pushViewController(controller, animated: true)
    }


    // MARK: - Document Editor Navigation

    func showCreateDocument(type: DocumentType) {
        let viewModel = DocumentEditorViewModel(
            mode: .create(type),
            router: self,
            documentsRepository: documentsRepository,
            documentFactory: documentFactory,
            documentValidator: documentValidator
        )

        let view = DocumentEditorScreen(viewModel: viewModel)
        let controller = HostingController(
            rootView: view,
            navigationTitle: viewModel.navigationTitle,
            titleDisplayMode: .never
        )

        navigationController.pushViewController(controller, animated: true)
    }

    func showDuplicateDocument(document: BusinessDocument) {
        let viewModel = DocumentEditorViewModel(
            mode: .duplicate(document),
            router: self,
            documentsRepository: documentsRepository,
            documentFactory: documentFactory,
            documentValidator: documentValidator
        )

        let view = DocumentEditorScreen(viewModel: viewModel)
        let controller = HostingController(
            rootView: view,
            navigationTitle: viewModel.navigationTitle,
            titleDisplayMode: .never
        )

        navigationController.pushViewController(controller, animated: true)
    }

    func showEditDocument(document: BusinessDocument) {
        let viewModel = DocumentEditorViewModel(
            mode: .edit(document),
            router: self,
            documentsRepository: documentsRepository,
            documentFactory: documentFactory,
            documentValidator: documentValidator
        )

        let view = DocumentEditorScreen(viewModel: viewModel)
        let controller = HostingController(
            rootView: view,
            navigationTitle: viewModel.navigationTitle,
            titleDisplayMode: .never
        )

        navigationController.pushViewController(controller, animated: true)
    }

    // MARK: - Document Preview Navigation

    func showPreview(document: BusinessDocument) {
        let viewModel = DocumentPreviewViewModel(
            document: document,
            router: self,
            htmlRenderer: documentHTMLRenderer,
            pdfGenerator: pdfGenerator
        )

        let view = DocumentPreviewScreen(viewModel: viewModel)
        let controller = HostingController(
            rootView: view,
            navigationTitle: "Предпросмотр",
            titleDisplayMode: .never
        )

        navigationController.pushViewController(controller, animated: true)
    }
    
    // MARK: - Flow Completion

    func finishDocumentFlowAfterShare() {
        navigationController.popToRootViewController(animated: true)
        documentsListViewModel?.handleDocumentsDidChange()
    }

    // MARK: - Generic Navigation Actions

    func dismiss() {
        navigationController.dismiss(animated: true)
    }

    func pop() {
        navigationController.popViewController(animated: true)
    }
}
