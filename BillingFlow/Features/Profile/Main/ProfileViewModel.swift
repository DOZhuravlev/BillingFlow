import Combine
import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {

    // MARK: - State

    @Published private(set) var primaryOrganization: Organization?

    // MARK: - Dependencies

    private let organizationsRepository: OrganizationsRepositoryProtocol

    // MARK: - Initialization

    init(organizationsRepository: OrganizationsRepositoryProtocol) {
        self.organizationsRepository = organizationsRepository
    }

    // MARK: - Loading

    func load() async {
        do {
            let organizations = try await organizationsRepository.fetchOrganizations()
            primaryOrganization = organizations.first { $0.isDefault && $0.role == .seller }
                ?? organizations.first { $0.role == .seller }
                ?? organizations.first { $0.isDefault }
        } catch {
            primaryOrganization = nil
        }
    }
}
