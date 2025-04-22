import Foundation

struct RemoteOrganizationSearchService: OrganizationSearchServiceProtocol {
    private let apiClient: APIClientProtocol
    private let mapper: OrganizationSuggestionMapper

    init(
        apiClient: APIClientProtocol,
        mapper: OrganizationSuggestionMapper = OrganizationSuggestionMapper()
    ) {
        self.apiClient = apiClient
        self.mapper = mapper
    }

    func searchOrganizations(query: String) async throws -> [OrganizationSuggestion] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.isEmpty == false else { return [] }

        let response: OrganizationSuggestionsResponseDTO = try await apiClient.request(
            APIEndpoint(
                path: "v1/billing/organizations/suggest",
                method: .post
            ),
            body: OrganizationSuggestRequestDTO(
                query: trimmedQuery,
                limit: 10
            )
        )

        return response.items.map(mapper.map)
    }
}
