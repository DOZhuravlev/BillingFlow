import SwiftUI

@MainActor
final class HomeCoordinator: HomeCoordinatorProtocol {

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
                                      documentsRepository: dependencies.documentsRepository,
                                      summaryService: MockFinanceSummaryService()
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

    }

    func showDocument(_ document: BusinessDocument) {

    }

    func showDocumentPreview(_ document: BusinessDocument) {

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

    }

    func pop() {

    }

}


