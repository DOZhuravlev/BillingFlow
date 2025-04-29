import SwiftUI

@MainActor
final class ProfileCoordinator: NSObject {

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
        super.init()
    }

    // MARK: - Public API

    func start() {
        let viewModel = ProfileViewModel(
            organizationsRepository: dependencies.organizationsRepository
        )

        let view = ProfileScreen(
            viewModel: viewModel,
            onOrganizationProfile: { [weak self] in
                self?.showOrganizationProfile()
            },
            onSignatureAndStamp: { [weak self] in
                self?.showSignatureAndStamp()
            },
            onNotifications: { [weak self] in
                self?.showNotificationSettings()
            }
        )

        let controller = HostingController(
            rootView: view,
            navigationTitle: "Профиль",
            titleDisplayMode: .never
        )

        controller.view.backgroundColor = .clear
        controller.edgesForExtendedLayout = [.top, .bottom]
        controller.extendedLayoutIncludesOpaqueBars = true

        navigationController.viewControllers = [controller]
        updateTabBarVisibility()
    }
}

// MARK: - Navigation

private extension ProfileCoordinator {
    func showOrganizationProfile() {
        let viewModel = OrganizationProfileSettingsViewModel(
            organizationsRepository: dependencies.organizationsRepository,
            organizationSearchService: dependencies.organizationSearchService
        )

        push(
            OrganizationProfileSettingsScreen(viewModel: viewModel),
            title: "Профиль организации"
        )
    }

    func showSignatureAndStamp() {
        push(
            SignatureStampSettingsScreen(),
            title: "Подпись и печать"
        )
    }

    func showNotificationSettings() {
        push(
            NotificationSettingsScreen(),
            title: "Уведомления"
        )
    }

    func push<Content: View>(
        _ view: Content,
        title: String
    ) {
        let controller = HostingController(
            rootView: view,
            navigationTitle: title,
            titleDisplayMode: .never
        )

        controller.view.backgroundColor = .clear
        controller.edgesForExtendedLayout = [.top, .bottom]
        controller.extendedLayoutIncludesOpaqueBars = true

        navigationController.pushViewController(controller, animated: true)
        updateTabBarVisibility()
    }
}

// MARK: - Tab Bar Visibility

extension ProfileCoordinator: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        updateTabBarVisibility()
    }
}

private extension ProfileCoordinator {
    func updateTabBarVisibility() {
        dependencies.tabBarVisibilityStore.setHidden(navigationController.viewControllers.count > 1)
    }
}
