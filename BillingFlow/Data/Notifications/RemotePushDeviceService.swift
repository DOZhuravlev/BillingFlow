import Foundation

protocol RemotePushDeviceServiceProtocol: Sendable {
    func registerDevice(_ device: PushDeviceRegistration) async throws
    func deleteDevice(id: String) async throws
}

struct RemotePushDeviceService: RemotePushDeviceServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func registerDevice(_ device: PushDeviceRegistration) async throws {
        let _: PushDeviceResponse = try await apiClient.request(
            APIEndpoint(
                path: "/v1/billing/devices/\(device.id)",
                method: .put
            ),
            body: device
        )
    }

    func deleteDevice(id: String) async throws {
        let _: PushDeviceResponse = try await apiClient.request(
            APIEndpoint(
                path: "/v1/billing/devices/\(id)",
                method: .delete
            ),
            body: nil
        )
    }
}

struct PushDeviceRegistration: Encodable, Sendable {
    let id: String
    let provider: String
    let token: String
    let platform: String
    let environment: String
    let appVersion: String
    let buildNumber: String
    let locale: String
    let timeZone: String
    let enabled: Bool
}

private struct PushDeviceResponse: Decodable {
    let ok: Bool
}
