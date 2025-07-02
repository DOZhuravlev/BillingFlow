import Foundation

struct RemoteNewsService: NewsServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func fetchNews() async throws -> [BillingNews] {
        let response: BillingNewsResponse = try await apiClient.request(
            APIEndpoint(path: "/v1/billing/news"),
            body: nil
        )

        return response.items.compactMap(map)
    }
}

private extension RemoteNewsService {
    func map(_ dto: BillingNewsDTO) -> BillingNews? {
        guard dto.isPublished, let id = UUID(uuidString: dto.id) else { return nil }
        return BillingNews(
            id: id,
            title: dto.title,
            body: dto.body,
            actionURL: dto.actionURL.flatMap(URL.init(string:)),
            updatedAt: Self.date(from: dto.updatedAt)
        )
    }

    static func date(from value: String) -> Date? {
        if let date = fractionalISO8601Formatter.date(from: value) {
            return date
        }
        return iso8601Formatter.date(from: value)
    }

    static let fractionalISO8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let iso8601Formatter = ISO8601DateFormatter()
}
