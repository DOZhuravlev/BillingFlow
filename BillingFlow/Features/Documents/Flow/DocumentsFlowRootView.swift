import SwiftUI

struct DocumentsFlowRootView: UIViewControllerRepresentable {

    @ObservedObject private var appRouteStore: AppRouteStore

    // MARK: - Dependencies

    private let dependencies: AppDependencies

    // MARK: - Initialization

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        self.appRouteStore = dependencies.appRouteStore
    }

    // MARK: - Root Navigation Setup

    func makeUIViewController(context: Context) -> UINavigationController {
        let navigationController = UINavigationController()

        let coordinator = DocumentsCoordinator(
            navigationController: navigationController,
            documentsRepository: dependencies.documentsRepository,
            organizationsRepository: dependencies.organizationsRepository,
            organizationSearchService: dependencies.organizationSearchService,
            appRouteStore: dependencies.appRouteStore,
            tabBarVisibilityStore: dependencies.tabBarVisibilityStore,
            documentEventsStore: dependencies.documentEventsStore,
            documentFactory: dependencies.documentFactory,
            documentValidator: dependencies.documentValidator,
            documentHTMLRenderer: dependencies.documentHTMLRenderer,
            pdfGenerator: dependencies.pdfGenerator
        )

        context.coordinator.documentsCoordinator = coordinator
        coordinator.start()

        return navigationController
    }

    // MARK: - UIKit Update Cycle

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        if let request = appRouteStore.documentCreationRequest {
            context.coordinator.documentsCoordinator?.showCreateDocument(type: request.type)
            appRouteStore.consumeDocumentCreationRequest(id: request.id)
        }

        if let request = appRouteStore.documentOpenRequest {
            context.coordinator.documentsCoordinator?.showDocument(id: request.documentID)
            appRouteStore.consumeDocumentOpenRequest(id: request.id)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var documentsCoordinator: DocumentsCoordinator?
    }
}
