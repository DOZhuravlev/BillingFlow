import SwiftUI

@MainActor
final class OrganizationsCoordinator {

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
    }

    // MARK: - Public API

    func start() {
        let viewModel = OrganizationsViewModel(
            organizationsRepository: dependencies.organizationsRepository,
            documentsRepository: dependencies.documentsRepository
        )
        let view = OrganizationsScreen(viewModel: viewModel)

        let controller = HostingController(
            rootView: view,
            navigationTitle: "Организации",
            titleDisplayMode: .never
        )

        controller.view.backgroundColor = .clear
        controller.edgesForExtendedLayout = [.top, .bottom]
        controller.extendedLayoutIncludesOpaqueBars = true

        navigationController.viewControllers = [controller]
    }
}
