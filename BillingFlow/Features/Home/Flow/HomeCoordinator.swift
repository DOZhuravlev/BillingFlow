import SwiftUI

@MainActor
final class HomeCoordinator: HomeCoordinatorProtocol, DocumentsCoordinatorProtocol {

    // MARK: - Navigation

    private let navigationController: UINavigationController

    // MARK: - Dependencies

    private let dependencies: AppDependencies

    // MARK: - Initialization

    init(
        navigationController: UINavigationController,
        dependencies: AppDependencies
    ) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }

    func start() {
        let viewModel = HomeViewModel(coordinator: self,
                                      documentsRepository: dependencies.documentsRepository
        )

        let view = HomeScreen(viewModel: viewModel)

        let controller = HostingController(
            rootView: view,
            navigationTitle: nil,
            titleDisplayMode: .never
        )

        navigationController.setNavigationBarHidden(true, animated: false)
        navigationController.viewControllers = [controller]
    }

    func showNotifications() {

    }

    func showProfile() {

    }

    func showCreateDocument(type: DocumentType) {
        showEditor(mode: .create(type))
    }

    func showDuplicateDocument(_ document: BusinessDocument) {
        showEditor(mode: .duplicate(document))
    }

    func showDocument(_ document: BusinessDocument) {
        showDetail(document: document)
    }

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

    func showDocumentPreview(_ document: BusinessDocument) {
        showPreview(document: document)
    }

    func showEditDocument(document: BusinessDocument) {
        showEditor(mode: .edit(document))
    }

    func showDuplicateDocument(document: BusinessDocument) {
        showDuplicateDocument(document)
    }

    func showPreview(document: BusinessDocument) {
        let viewModel = DocumentPreviewViewModel(
            document: document,
            router: self,
            htmlRenderer: dependencies.documentHTMLRenderer,
            pdfGenerator: dependencies.pdfGenerator
        )

        let view = DocumentPreviewScreen(viewModel: viewModel)
        let controller = HostingController(
            rootView: view,
            navigationTitle: "Предпросмотр",
            titleDisplayMode: .never
        )

        navigationController.pushViewController(controller, animated: true)
    }

    func showAllDocuments() {

    }

    func showOrganization(_ organization: UUID) {

    }

    func showAllOrganizations() {

    }

    func showFinanceDetails(filter: HomeFinanceFilter) {

    }

    func dismiss() {
        navigationController.dismiss(animated: true)
    }

    func pop() {
        navigationController.popViewController(animated: true)
    }

    func finishDocumentFlowAfterShare() {
        navigationController.popToRootViewController(animated: true)
    }
}

private extension HomeCoordinator {
    func showEditor(mode: DocumentEditorViewModel.Mode) {
        let viewModel = DocumentEditorViewModel(
            mode: mode,
            router: self,
            documentsRepository: dependencies.documentsRepository,
            documentFactory: dependencies.documentFactory,
            documentValidator: dependencies.documentValidator
        )

        let view = DocumentEditorScreen(viewModel: viewModel)
        let controller = HostingController(
            rootView: view,
            navigationTitle: viewModel.navigationTitle,
            titleDisplayMode: .never
        )

        navigationController.pushViewController(controller, animated: true)
    }
}

