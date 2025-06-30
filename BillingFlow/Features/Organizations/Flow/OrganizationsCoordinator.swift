import SwiftUI

@MainActor
final class OrganizationsCoordinator: NSObject, DocumentsCoordinatorProtocol {

    // MARK: - Dependencies

    private let navigationController: UINavigationController
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

    // MARK: - Public API

    func start() {
        navigationController.delegate = self
        navigationController.setNavigationBarHidden(true, animated: false)

        let viewModel = OrganizationsViewModel(
            organizationsRepository: dependencies.organizationsRepository,
            documentsRepository: dependencies.documentsRepository,
            documentEventsStore: dependencies.documentEventsStore,
            organizationEventsStore: dependencies.organizationEventsStore
        )
        let view = OrganizationsScreen(
            viewModel: viewModel,
            onSelect: { [weak self] item in
                self?.showDetail(item: item)
            }
        )

        let controller = HostingController(
            rootView: view,
            navigationTitle: "Контрагенты",
            titleDisplayMode: .never
        )

        controller.view.backgroundColor = .clear
        controller.edgesForExtendedLayout = [.top, .bottom]
        controller.extendedLayoutIncludesOpaqueBars = true

        navigationController.viewControllers = [controller]
        updateTabBarVisibility()
    }

    func showDetail(item: OrganizationsViewModel.Item) {
        let viewModel = OrganizationDetailViewModel(
            item: item,
            coordinator: self
        )
        let view = OrganizationDetailScreen(viewModel: viewModel)

        let controller = HostingController(
            rootView: view,
            navigationTitle: "Контрагент",
            titleDisplayMode: .never
        )

        controller.view.backgroundColor = .clear
        controller.edgesForExtendedLayout = [.top, .bottom]
        controller.extendedLayoutIncludesOpaqueBars = true

        navigationController.pushViewController(controller, animated: true)
        updateTabBarVisibility()
    }

    func showDetail(document: BusinessDocument) {
        guard document.status != .draft else {
            showEditor(mode: .resumeDraft(document))
            return
        }

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

    func showCreateDocument(type: DocumentType) {
        showEditor(mode: .create(type))
    }

    func showCreateDocument(type: DocumentType, buyer: DocumentParty) {
        showEditor(mode: .create(type, buyer: buyer))
    }

    func showDuplicateDocument(document: BusinessDocument) {
        showEditor(mode: .duplicate(document))
    }

    func showEditDocument(document: BusinessDocument) {
        let mode: DocumentEditorViewModel.Mode = document.status == .draft
            ? .resumeDraft(document)
            : .edit(document)
        showEditor(mode: mode)
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

    func finishDocumentFlowAfterShare() {
        navigationController.popToRootViewController(animated: true)
        updateTabBarVisibility()
    }

    func finishDocumentFlowAfterSave() {
        navigationController.popToRootViewController(animated: true)
        updateTabBarVisibility()
    }

    func dismiss() {
        navigationController.dismiss(animated: true)
    }

    func pop() {
        navigationController.popViewController(animated: true)
        updateTabBarVisibility()
    }
}

// MARK: - Navigation Controller Delegate

extension OrganizationsCoordinator: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        updateTabBarVisibility()
    }
}

// MARK: - Tab Bar Visibility

private extension OrganizationsCoordinator {
    func updateTabBarVisibility() {
        dependencies.tabBarVisibilityStore.setHidden(navigationController.viewControllers.count > 1)
    }

    func showEditor(mode: DocumentEditorViewModel.Mode) {
        let viewModel = DocumentEditorViewModel(
            mode: mode,
            router: self,
            documentsRepository: dependencies.documentsRepository,
            organizationsRepository: dependencies.organizationsRepository,
            organizationSearchService: dependencies.organizationSearchService,
            appRouteStore: dependencies.appRouteStore,
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

    func showPreview(
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
}
