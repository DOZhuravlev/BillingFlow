import SwiftUI

struct OrganizationsFlowRootView: UIViewControllerRepresentable {

    // MARK: - Dependencies

    private let dependencies: AppDependencies

    // MARK: - Initialization

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    // MARK: - Public API

    func makeUIViewController(context: Context) -> UINavigationController {
        let navigationController = UINavigationController()

        configureNavigationController(navigationController)

        let coordinator = OrganizationsCoordinator(
            navigationController: navigationController,
            dependencies: dependencies
        )

        context.coordinator.organizationsCoordinator = coordinator
        coordinator.start()

        return navigationController
    }

    func updateUIViewController(
        _ uiViewController: UINavigationController,
        context: Context
    ) { }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}

private extension OrganizationsFlowRootView {
    func configureNavigationController(_ navigationController: UINavigationController) {
        navigationController.view.backgroundColor = .clear
        navigationController.navigationBar.isTranslucent = true

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear

        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        navigationController.navigationBar.compactScrollEdgeAppearance = appearance
    }
}

extension OrganizationsFlowRootView {
    final class Coordinator {
        var organizationsCoordinator: OrganizationsCoordinator?
    }
}
