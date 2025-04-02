import SwiftUI
import Combine

@MainActor
final class AppCoordinator: ObservableObject {

    // MARK: - Dependencies

    private let dependencies: AppDependencies

    // MARK: - Published Properties

    @Published var selectedTab: AppTab = .home
    @Published var activeSheet: AppSheet?
    @Published var activeFullScreenCover: AppFullScreenCover?

    // MARK: - State

    private var didStart = false

    // MARK: - Initialization

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    func start() {
        guard didStart == false else { return }

        didStart = true
        handleInitialLaunch()
    }

    func selectTab(_ tab: AppTab) {
        selectedTab = tab
    }

    func handleCreateDocumentTap() {
        showCreateDocument()

        // if dependencies.entitlementsService.canCreateDocument {
        //     showCreateDocument()
        // } else {
        //     showPaywall(source: .documentLimit)
        // }
    }

    func showCreateDocument() {
        activeSheet = .createDocument
    }

    func showPaywall(source: PaywallSource) {
        activeSheet = .paywall(source)
    }

    func showOrganizationSwitcher() {
        activeSheet = .organizationSwitcher
    }

    func showOnboarding() {
        activeFullScreenCover = .onboarding
    }

    func finishDocumentCreation() {
        activeSheet = nil
        selectedTab = .documents
    }

    func finishOnboarding() {
        // dependencies.onboardingStore.markCompleted()

        activeFullScreenCover = nil
    }

    func dismissSheet() {
        activeSheet = nil
    }

    func dismissFullScreenCover() {
        activeFullScreenCover = nil
    }

    private func handleInitialLaunch() {
        // guard dependencies.onboardingStore.hasCompletedOnboarding == false else {
        //     return
        // }
        //
        // showOnboarding()
    }
}
