import SwiftUI

struct DealsFlowRootView: UIViewControllerRepresentable {
    @ObservedObject private var appRouteStore: AppRouteStore
    private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        self.appRouteStore = dependencies.appRouteStore
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let navigationController = UINavigationController()
        let coordinator = DealsCoordinator(navigationController: navigationController, dependencies: dependencies)
        context.coordinator.coordinator = coordinator
        coordinator.start()
        return navigationController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        guard let request = appRouteStore.dealCreationRequest else { return }
        context.coordinator.coordinator?.showCreateDeal(type: request.type)
        appRouteStore.consumeDealCreationRequest(id: request.id)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var coordinator: DealsCoordinator?
    }
}
