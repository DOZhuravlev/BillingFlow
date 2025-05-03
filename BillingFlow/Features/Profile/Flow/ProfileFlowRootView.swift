import SwiftUI

struct ProfileFlowRootView: UIViewControllerRepresentable {

    // MARK: - State

    @ObservedObject private var appRouteStore: AppRouteStore

    // MARK: - Dependencies

    private let dependencies: AppDependencies

    // MARK: - Initialization

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        self.appRouteStore = dependencies.appRouteStore
    }

    // MARK: - Public API

    func makeUIViewController(context: Context) -> UINavigationController {
        let navigationController = UINavigationController()

        configureNavigationController(navigationController)

        let coordinator = ProfileCoordinator(
            navigationController: navigationController,
            dependencies: dependencies
        )

        context.coordinator.profileCoordinator = coordinator
        navigationController.delegate = coordinator
        coordinator.start()

        return navigationController
    }

    func updateUIViewController(
        _ uiViewController: UINavigationController,
        context: Context
    ) {
        guard let requestID = appRouteStore.organizationProfileRequestID else { return }

        context.coordinator.profileCoordinator?.showOrganizationProfileSettings()
        appRouteStore.consumeOrganizationProfileRequest(id: requestID)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}

private extension ProfileFlowRootView {
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

extension ProfileFlowRootView {
    final class Coordinator {
        var profileCoordinator: ProfileCoordinator?
    }
}
