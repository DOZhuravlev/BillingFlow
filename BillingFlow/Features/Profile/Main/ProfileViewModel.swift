import Combine
import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {

    // MARK: - State

    @Published private(set) var primaryOrganization: Organization?

    // MARK: - Dependencies

    private let organizationsRepository: OrganizationsRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        organizationsRepository: OrganizationsRepositoryProtocol,
        organizationEventsStore: OrganizationEventsStore? = nil
    ) {
        self.organizationsRepository = organizationsRepository
        organizationEventsStore?
            .organizationsDidChangePublisher
            .sink { [weak self] in
                Task { await self?.load() }
            }
            .store(in: &cancellables)
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
