import Foundation

protocol OrganizationSearchServiceProtocol: Sendable {
    func searchOrganizations(query: String) async throws -> [OrganizationSuggestion]
}
