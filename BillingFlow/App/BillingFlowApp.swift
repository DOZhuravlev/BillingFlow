import SwiftUI

@main
struct BillingFlowApp: App {
    private let appDependencies = AppDependenciesFactory.make()

    var body: some Scene {
        WindowGroup {
            AppRootView(dependencies: appDependencies)
        }
    }
}
