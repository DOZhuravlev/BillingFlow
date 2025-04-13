import SwiftUI

@MainActor
final class ProfileCoordinator {

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
        let view = ProfileScreen()

        let controller = HostingController(
            rootView: view,
            navigationTitle: "Профиль",
            titleDisplayMode: .never
        )

        controller.view.backgroundColor = .clear
        controller.edgesForExtendedLayout = [.top, .bottom]
        controller.extendedLayoutIncludesOpaqueBars = true

        navigationController.viewControllers = [controller]
    }
}
