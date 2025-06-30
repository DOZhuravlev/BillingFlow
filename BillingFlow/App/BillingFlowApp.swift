import SwiftUI

@main
struct BillingFlowApp: App {
    @UIApplicationDelegateAdaptor(PushAppDelegate.self) private var pushAppDelegate

    private let appDependencies = AppDependenciesFactory.make()

    var body: some Scene {
        WindowGroup {
            AppRootView(dependencies: appDependencies)
        }
    }
}
