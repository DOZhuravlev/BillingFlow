import SwiftUI
import UIKit

@MainActor
final class DealsCoordinator: NSObject, DealsCoordinatorProtocol, DocumentsCoordinatorProtocol {
    private let navigationController: UINavigationController
    private let dependencies: AppDependencies
    private weak var documentFlowReturnController: UIViewController?

    init(navigationController: UINavigationController, dependencies: AppDependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
        super.init()
    }

    func start() {
        navigationController.delegate = self
        navigationController.setNavigationBarHidden(true, animated: false)
        let viewModel = DealsListViewModel(
            coordinator: self,
            dealsRepository: dependencies.dealsRepository,
            documentsRepository: dependencies.documentsRepository,
            dealEventsStore: dependencies.dealEventsStore,
            documentEventsStore: dependencies.documentEventsStore
        )
        navigationController.viewControllers = [HostingController(rootView: DealsListScreen(viewModel: viewModel), navigationTitle: "Сделки", titleDisplayMode: .never)]
    }

    func showCreateDeal(type: DealType) {
        let viewModel = DealCreateViewModel(
            type: type,
            coordinator: self,
            dealsRepository: dependencies.dealsRepository,
            organizationsRepository: dependencies.organizationsRepository,
            dealEventsStore: dependencies.dealEventsStore
        )
        push(DealCreateScreen(viewModel: viewModel), title: "Новая сделка")
    }

    func finishDealCreation(_ deal: Deal) {
        navigationController.popViewController(animated: false)
        showDeal(deal)
    }

    func showDeal(_ deal: Deal) {
        let viewModel = DealDetailViewModel(
            deal: deal,
            coordinator: self,
            dealsRepository: dependencies.dealsRepository,
            documentsRepository: dependencies.documentsRepository,
            dealEventsStore: dependencies.dealEventsStore,
            documentEventsStore: dependencies.documentEventsStore
        )
        push(DealDetailScreen(viewModel: viewModel), title: deal.title)
    }

    func createDocument(type: DocumentType, for deal: Deal) {
        documentFlowReturnController = navigationController.topViewController
        showEditor(mode: .create(type, buyer: deal.counterparty, dealID: deal.id))
    }

    func showDocument(_ document: BusinessDocument) { showDetail(document: document) }

    func showDetail(document: BusinessDocument) {
        if document.status == .draft {
            documentFlowReturnController = navigationController.topViewController
            showEditor(mode: .resumeDraft(document))
            return
        }
        let viewModel = DocumentDetailViewModel(document: document, coordinator: self)
        push(DocumentDetailScreen(viewModel: viewModel), title: "Документ")
    }

    func showCreateDocument(type: DocumentType) { showEditor(mode: .create(type)) }
    func showCreateDocument(type: DocumentType, buyer: DocumentParty) { showEditor(mode: .create(type, buyer: buyer)) }
    func showDuplicateDocument(document: BusinessDocument) { showEditor(mode: .duplicate(document)) }
    func showEditDocument(document: BusinessDocument) { showEditor(mode: document.status == .draft ? .resumeDraft(document) : .edit(document)) }

    func showPreview(document: BusinessDocument) {
        showPreview(document: document, saveAction: nil, signAndSendAction: nil)
    }

    func showPreview(document: BusinessDocument, saveAction: @escaping () async -> Void, signAndSendAction: @escaping () async -> Void) {
        showPreview(document: document, saveAction: Optional(saveAction), signAndSendAction: Optional(signAndSendAction))
    }

    private func showPreview(document: BusinessDocument, saveAction: (() async -> Void)?, signAndSendAction: (() async -> Void)?) {
        let viewModel = DocumentPreviewViewModel(
            document: document,
            router: self,
            htmlRenderer: dependencies.documentHTMLRenderer,
            pdfGenerator: dependencies.pdfGenerator,
            saveAction: saveAction,
            signAndSendAction: signAndSendAction
        )
        push(DocumentPreviewScreen(viewModel: viewModel), title: "Предпросмотр")
    }

    func finishDocumentFlowAfterShare() { finishDocumentFlowAfterSave() }
    func finishDocumentFlowAfterSave() {
        if let returnController = documentFlowReturnController,
           navigationController.viewControllers.contains(returnController) {
            navigationController.popToViewController(returnController, animated: true)
        } else {
            navigationController.popToRootViewController(animated: true)
        }
        documentFlowReturnController = nil
        updateTabBarVisibility()
    }

    func dismiss() { navigationController.dismiss(animated: true) }
    func pop() { navigationController.popViewController(animated: true); updateTabBarVisibility() }

    private func showEditor(mode: DocumentEditorViewModel.Mode) {
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
        push(DocumentEditorScreen(viewModel: viewModel), title: viewModel.navigationTitle)
    }

    private func push<Content: View>(_ view: Content, title: String) {
        let controller = HostingController(rootView: view, navigationTitle: title, titleDisplayMode: .never)
        controller.view.backgroundColor = .clear
        navigationController.pushViewController(controller, animated: true)
        updateTabBarVisibility()
    }

    private func updateTabBarVisibility() {
        dependencies.tabBarVisibilityStore.setHidden(navigationController.viewControllers.count > 1)
    }
}

extension DealsCoordinator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        updateTabBarVisibility()
    }
}
