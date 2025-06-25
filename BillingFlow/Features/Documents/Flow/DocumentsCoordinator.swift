import UIKit

@MainActor
final class DocumentsCoordinator: NSObject, DocumentsCoordinatorProtocol {

    // MARK: - Navigation

    private let navigationController: UINavigationController

    // MARK: - Document Data Dependencies

    private let documentsRepository: DocumentsRepositoryProtocol
    private let organizationsRepository: OrganizationsRepositoryProtocol
    private let organizationSearchService: OrganizationSearchServiceProtocol
    private let appRouteStore: AppRouteStore
    private let tabBarVisibilityStore: TabBarVisibilityStore
    private let documentEventsStore: DocumentEventsStore
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
        organizationsRepository: OrganizationsRepositoryProtocol,
        organizationSearchService: OrganizationSearchServiceProtocol,
        appRouteStore: AppRouteStore,
        tabBarVisibilityStore: TabBarVisibilityStore,
        documentEventsStore: DocumentEventsStore,
        documentFactory: DocumentFactory,
        documentValidator: DocumentValidator,
        documentHTMLRenderer: DocumentHTMLRenderer,
        pdfGenerator: PDFGenerator
    ) {
        self.navigationController = navigationController
        self.documentsRepository = documentsRepository
        self.organizationsRepository = organizationsRepository
        self.organizationSearchService = organizationSearchService
        self.appRouteStore = appRouteStore
        self.tabBarVisibilityStore = tabBarVisibilityStore
        self.documentEventsStore = documentEventsStore
        self.documentFactory = documentFactory
        self.documentValidator = documentValidator
        self.documentHTMLRenderer = documentHTMLRenderer
        self.pdfGenerator = pdfGenerator
        super.init()
    }

    // MARK: - Start coordinator

    func start() {
        navigationController.delegate = self

        let viewModel = DocumentsListViewModel(
            coordinator: self,
            documentsRepository: documentsRepository,
            documentEventsStore: documentEventsStore
        )

        documentsListViewModel = viewModel

        let view = DocumentsScreen(viewModel: viewModel)

        let controller = HostingController(
            rootView: view,
            navigationTitle: "Документы"
        )

        navigationController.setNavigationBarHidden(true, animated: false)
        navigationController.viewControllers = [controller]
    }

    // MARK: - Document Detail Navigation

    func showDetail(document: BusinessDocument) {
        guard document.status != .draft else {
            showEditDocument(document: document)
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


    // MARK: - Document Editor Navigation

    func showCreateDocument(type: DocumentType) {
        let viewModel = DocumentEditorViewModel(
            mode: .create(type),
            router: self,
            documentsRepository: documentsRepository,
            organizationsRepository: organizationsRepository,
            organizationSearchService: organizationSearchService,
            appRouteStore: appRouteStore,
            documentEventsStore: documentEventsStore,
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
        updateTabBarVisibility()
    }

    func showDuplicateDocument(document: BusinessDocument) {
        let viewModel = DocumentEditorViewModel(
            mode: .duplicate(document),
            router: self,
            documentsRepository: documentsRepository,
            organizationsRepository: organizationsRepository,
            organizationSearchService: organizationSearchService,
            appRouteStore: appRouteStore,
            documentEventsStore: documentEventsStore,
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
        updateTabBarVisibility()
    }

    func showEditDocument(document: BusinessDocument) {
        let viewModel = DocumentEditorViewModel(
            mode: document.status == .draft ? .resumeDraft(document) : .edit(document),
            router: self,
            documentsRepository: documentsRepository,
            organizationsRepository: organizationsRepository,
            organizationSearchService: organizationSearchService,
            appRouteStore: appRouteStore,
            documentEventsStore: documentEventsStore,
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
        updateTabBarVisibility()
    }

    // MARK: - Document Preview Navigation

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
            htmlRenderer: documentHTMLRenderer,
            pdfGenerator: pdfGenerator,
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
    
    // MARK: - Flow Completion

    func finishDocumentFlowAfterShare() {
        navigationController.popToRootViewController(animated: true)
        documentsListViewModel?.handleDocumentsDidChange()
        updateTabBarVisibility()
    }

    func finishDocumentFlowAfterSave() {
        navigationController.popToRootViewController(animated: true)
        documentsListViewModel?.handleDocumentsDidChange()
        updateTabBarVisibility()
    }

    // MARK: - Generic Navigation Actions

    func dismiss() {
        navigationController.dismiss(animated: true)
    }

    func pop() {
        navigationController.popViewController(animated: true)
        updateTabBarVisibility()
    }
}

// MARK: - UINavigationControllerDelegate

extension DocumentsCoordinator: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        updateTabBarVisibility()
    }
}

// MARK: - Tab Bar Visibility

private extension DocumentsCoordinator {
    func updateTabBarVisibility() {
        tabBarVisibilityStore.setHidden(navigationController.viewControllers.count > 1)
    }
}
