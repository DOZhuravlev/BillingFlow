import SwiftUI

struct HomeFlowRootView: UIViewControllerRepresentable {

    // MARK: - Dependencies

    private let dependencies: AppDependencies

    // MARK: - Initialization

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    // MARK: - Root Navigation Setup

    func makeUIViewController(context: Context) -> UINavigationController {
        let navigationController = UINavigationController()

        let coordinator = HomeCoordinator(
            navigationController: navigationController,
            dependencies: dependencies
        )

        context.coordinator.homeCoordinator = coordinator
        coordinator.start()

        return navigationController
    }

    // MARK: - UIKit Update Cycle

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var homeCoordinator: HomeCoordinator?
    }
}
