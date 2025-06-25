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
        navigationController.setNavigationBarHidden(true, animated: false)

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

    func showOrganizationProfileSettings() {
        navigationController.popToRootViewController(animated: false)
        showOrganizationProfile()
    }
}

// MARK: - Navigation

private extension ProfileCoordinator {
    func showOrganizationProfile() {
        navigationController.setNavigationBarHidden(true, animated: false)

        let viewModel = OrganizationProfileSettingsViewModel(
            organizationsRepository: dependencies.organizationsRepository,
            organizationSearchService: dependencies.organizationSearchService
        )

        push(
            OrganizationProfileSettingsScreen(
                viewModel: viewModel,
                onBack: { [weak self] in
                    self?.pop()
                }
            ),
            title: "Профиль организации"
        )
    }

    func showSignatureAndStamp() {
        navigationController.setNavigationBarHidden(true, animated: false)
        push(
            SignatureStampSettingsScreen(onBack: { [weak self] in
                self?.pop()
            }),
            title: "Подпись и печать"
        )
    }

    func showNotificationSettings() {
        navigationController.setNavigationBarHidden(true, animated: false)
        push(
            NotificationSettingsScreen(onBack: { [weak self] in
                self?.pop()
            }),
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

    func pop() {
        navigationController.popViewController(animated: true)
        if navigationController.viewControllers.count == 1 {
            navigationController.setNavigationBarHidden(true, animated: false)
        }
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
