import SwiftUI

@MainActor
final class HomeCoordinator: NSObject, HomeCoordinatorProtocol, DocumentsCoordinatorProtocol {

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
        super.init()
    }

    func start() {
        navigationController.delegate = self

        let viewModel = HomeViewModel(coordinator: self,
                                      documentsRepository: dependencies.documentsRepository,
                                      documentEventsStore: dependencies.documentEventsStore
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
        updateTabBarVisibility()
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
        showPreview(
            document: document,
            saveAction: nil,
            signAndSendAction: nil
        )
    }

    func showPreview(
        document: BusinessDocument,
        saveAction: @escaping () async -> Void,
        signAndSendAction: @escaping () async -> Void
    ) {
        showPreview(
            document: document,
            saveAction: Optional(saveAction),
            signAndSendAction: Optional(signAndSendAction)
        )
    }

    private func showPreview(
        document: BusinessDocument,
        saveAction: (() async -> Void)?,
        signAndSendAction: (() async -> Void)?
    ) {
        let viewModel = DocumentPreviewViewModel(
            document: document,
            router: self,
            htmlRenderer: dependencies.documentHTMLRenderer,
            pdfGenerator: dependencies.pdfGenerator,
            saveAction: saveAction,
            signAndSendAction: signAndSendAction
        )

        let view = DocumentPreviewScreen(viewModel: viewModel)
        let controller = HostingController(
            rootView: view,
            navigationTitle: "Предпросмотр",
            titleDisplayMode: .never
        )

        navigationController.pushViewController(controller, animated: true)
        updateTabBarVisibility()
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
        updateTabBarVisibility()
    }

    func finishDocumentFlowAfterSave() {
        navigationController.popToRootViewController(animated: true)
        updateTabBarVisibility()
    }
}

// MARK: - UINavigationControllerDelegate

extension HomeCoordinator: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        updateTabBarVisibility()
    }
}

// MARK: - Tab Bar Visibility

private extension HomeCoordinator {
    func updateTabBarVisibility() {
        dependencies.tabBarVisibilityStore.setHidden(navigationController.viewControllers.count > 1)
    }
}

private extension HomeCoordinator {
    func showEditor(mode: DocumentEditorViewModel.Mode) {
        let viewModel = DocumentEditorViewModel(
            mode: mode,
            router: self,
            documentsRepository: dependencies.documentsRepository,
            organizationsRepository: dependencies.organizationsRepository,
            documentEventsStore: dependencies.documentEventsStore,
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
        updateTabBarVisibility()
    }
}
