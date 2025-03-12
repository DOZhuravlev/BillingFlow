import SwiftUI

@main
struct BillingFlowApp: App {
    var body: some Scene {
        WindowGroup {
            DocumentsScreen(repository: InMemoryDocumentsRepository())
        }
    }
}
