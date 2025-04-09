import SwiftUI

struct AppRootView: View {

    // MARK: - State

    @StateObject private var appCoordinator: AppCoordinator

    // MARK: - Dependencies

    private let dependencies: AppDependencies

    // MARK: - Initialization

    init(dependencies: AppDependencies) {
          self.dependencies = dependencies
          _appCoordinator = StateObject(
              wrappedValue: AppCoordinator(dependencies: dependencies)
          )
      }


    var body: some View {
        ZStack {
            tabContent
        }
        .overlay(alignment: .bottom) {
            CustomTabView(
                selection: $appCoordinator.selectedTab,
                onCreateTap: {
                    appCoordinator.handleCreateDocumentTap()
                }
            )
            .offset(y: 20)
        }
        .sheet(item: $appCoordinator.activeSheet) { sheet in
            //sheetView(sheet)
        }
        .fullScreenCover(item: $appCoordinator.activeFullScreenCover) { cover in
            //fullScreenCoverView(cover)
        }
        .task {
            appCoordinator.start()
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        HomeFlowRootView(dependencies: dependencies)
            .ignoresSafeArea()
            .opacity(appCoordinator.selectedTab == .home ? 1 : 0)
            .allowsHitTesting(appCoordinator.selectedTab == .home)

        DocumentsFlowRootView(dependencies: dependencies)
            .ignoresSafeArea()
            .opacity(appCoordinator.selectedTab == .documents ? 1 : 0)
            .allowsHitTesting(appCoordinator.selectedTab == .documents)

        //CounterpartiesFlowRootView(dependencies: appDependencies)
        TestHomeFlowRootView(dependencies: dependencies)
            .ignoresSafeArea()
            .opacity(appCoordinator.selectedTab == .counterparties ? 1 : 0)
            .allowsHitTesting(appCoordinator.selectedTab == .counterparties)

        //MoreFlowRootView(dependencies: appDependencies)
        EmptyView()
            .ignoresSafeArea()
            .opacity(appCoordinator.selectedTab == .more ? 1 : 0)
            .allowsHitTesting(appCoordinator.selectedTab == .more)

    }

    @ViewBuilder
    private func sheetView(_ sheet: AppSheet) -> some View {
        switch sheet {
        case .createDocument:
            DocumentCreatePlaceholderView(
                onClose: {
                    appCoordinator.dismissSheet()
                },
                onFinish: {
                    appCoordinator.finishDocumentCreation()
                }
            )

        case .paywall(let source):
            PaywallPlaceholderView(
                source: source,
                onClose: {
                    appCoordinator.dismissSheet()
                }
            )

        case .organizationSwitcher:
            OrganizationSwitcherPlaceholderView(
                onClose: {
                    appCoordinator.dismissSheet()
                }
            )
        }
    }

    @ViewBuilder
        private func fullScreenCoverView(_ cover: AppFullScreenCover) -> some View {
            switch cover {
            case .onboarding:
                OnboardingPlaceholderView(
                    onFinish: {
                        appCoordinator.finishOnboarding()
                    }
                )
            }
        }
}


import SwiftUI

struct TestHomeFlowRootView: UIViewControllerRepresentable {

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

        let coordinator = TestHomeCoordinator(
            navigationController: navigationController,
            dependencies: dependencies
        )

        context.coordinator.testHomeCoordinator = coordinator
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

    // MARK: - Private API / Helpers

    private func configureNavigationController(_ navigationController: UINavigationController) {
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

    final class Coordinator {
        var testHomeCoordinator: TestHomeCoordinator?
    }
}


import SwiftUI

@MainActor
final class TestHomeCoordinator {

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
        let view = TestHomeScreen()

        let controller = HostingController(
            rootView: view,
            navigationTitle: "Тест Home",
            titleDisplayMode: .never
        )

        controller.view.backgroundColor = .clear
        controller.edgesForExtendedLayout = [.top, .bottom]
        controller.extendedLayoutIncludesOpaqueBars = true

        navigationController.viewControllers = [controller]
    }
}



import SwiftUI

struct TestHomeScreen: View {

    // MARK: - Body

    var body: some View {
        ZStack {
            background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("TEST HOME")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text("Проверяем фон под safe area")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    // MARK: - Private API / Helpers

    private var background: some View {
        LinearGradient(
            colors: [
                Color.red,
                Color.orange,
                Color.purple
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
