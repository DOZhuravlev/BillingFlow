import Foundation

protocol NewsServiceProtocol: Sendable {
    func fetchNews() async throws -> [BillingNews]
}
