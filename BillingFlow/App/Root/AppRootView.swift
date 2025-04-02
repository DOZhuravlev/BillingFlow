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
            .padding(.bottom, 12)
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
        //DocumentsFlowRootView(dependencies: appDependencies)
        EmptyView()
            .opacity(appCoordinator.selectedTab == .home ? 1 : 0)

            .allowsHitTesting(appCoordinator.selectedTab == .home)

        DocumentsFlowRootView(dependencies: dependencies)
            .opacity(appCoordinator.selectedTab == .documents ? 1 : 0)
            .allowsHitTesting(appCoordinator.selectedTab == .documents)

        //CounterpartiesFlowRootView(dependencies: appDependencies)
        EmptyView()
            .opacity(appCoordinator.selectedTab == .counterparties ? 1 : 0)

            .allowsHitTesting(appCoordinator.selectedTab == .counterparties)

        //MoreFlowRootView(dependencies: appDependencies)
        EmptyView()
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
