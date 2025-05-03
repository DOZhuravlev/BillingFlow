import Combine
import Foundation

@MainActor
final class AppRouteStore: ObservableObject {

    @Published private(set) var organizationProfileRequestID: UUID?

    func openOrganizationProfile() {
        organizationProfileRequestID = UUID()
    }

    func consumeOrganizationProfileRequest(id: UUID) {
        guard organizationProfileRequestID == id else { return }
        organizationProfileRequestID = nil
    }
}
