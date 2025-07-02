import SwiftUI

struct AppRootView: View {

    // MARK: - State

    @StateObject private var appCoordinator: AppCoordinator
    @ObservedObject private var tabBarVisibilityStore: TabBarVisibilityStore
    @ObservedObject private var appRouteStore: AppRouteStore

    // MARK: - Dependencies

    private let dependencies: AppDependencies

    // MARK: - Initialization

    init(dependencies: AppDependencies) {
          self.dependencies = dependencies
          self.tabBarVisibilityStore = dependencies.tabBarVisibilityStore
          self.appRouteStore = dependencies.appRouteStore
          _appCoordinator = StateObject(
              wrappedValue: AppCoordinator(dependencies: dependencies)
          )
      }


    var body: some View {
        ZStack {
            tabContent
        }
        .overlay(alignment: .bottom) {
            if tabBarVisibilityStore.isHidden == false {
                CustomTabView(
                    selection: $appCoordinator.selectedTab,
                    onCreateDocument: { type in
                        appCoordinator.createDocument(type: type)
                    }
                )
                .offset(y: 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: tabBarVisibilityStore.isHidden)
        .onChange(of: appRouteStore.organizationProfileRequestID) { requestID in
            guard requestID != nil else { return }
            appCoordinator.selectTab(.profile)
        }
        .onChange(of: appRouteStore.dealCreationRequest) { request in
            guard request != nil else { return }
            appCoordinator.selectTab(.deals)
        }
        .onChange(of: appRouteStore.documentCreationRequest) { request in
            guard request != nil else { return }
            appCoordinator.selectTab(.documents)
        }
        .onChange(of: appRouteStore.documentOpenRequest) { request in
            guard request != nil else { return }
            appCoordinator.selectTab(.documents)
        }
        .onChange(of: appRouteStore.newsOpenRequest) { request in
            guard request != nil else { return }
            appCoordinator.selectTab(.home)
        }
        .sheet(item: $appCoordinator.activeSheet) { sheet in
            //sheetView(sheet)
        }
        .fullScreenCover(item: $appCoordinator.activeFullScreenCover) { cover in
            //fullScreenCoverView(cover)
        }
        .task {
            appCoordinator.start()
            dependencies.syncCoordinator.start()
            dependencies.notificationCoordinator.start()
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

        DealsFlowRootView(dependencies: dependencies)
            .ignoresSafeArea()
            .opacity(appCoordinator.selectedTab == .deals ? 1 : 0)
            .allowsHitTesting(appCoordinator.selectedTab == .deals)

        OrganizationsFlowRootView(dependencies: dependencies)
            .ignoresSafeArea()
            .opacity(appCoordinator.selectedTab == .organizations ? 1 : 0)
            .allowsHitTesting(appCoordinator.selectedTab == .organizations)

        ProfileFlowRootView(dependencies: dependencies)
            .ignoresSafeArea()
            .opacity(appCoordinator.selectedTab == .profile ? 1 : 0)
            .allowsHitTesting(appCoordinator.selectedTab == .profile)

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
