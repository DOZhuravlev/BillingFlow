import Foundation

nonisolated struct OrganizationsSyncState: Codable, Sendable {
    var ownerUserID: String?
    var revisions: [UUID: Int64] = [:]
    var pendingUpserts: Set<UUID> = []
    var pendingDeletes: Set<UUID> = []
}

nonisolated struct OrganizationsSyncStateStore: Sendable {
    private let fileURL: URL

    init(fileManager: FileManager = .default, directoryURL: URL? = nil) {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = (directoryURL ?? baseURL.appendingPathComponent("BillingFlow", isDirectory: true))
            .appendingPathComponent("organizations-sync.json")
    }

    func load() throws -> OrganizationsSyncState {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return OrganizationsSyncState()
        }
        return try JSONDecoder().decode(OrganizationsSyncState.self, from: Data(contentsOf: fileURL))
    }

    func save(_ state: OrganizationsSyncState) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try JSONEncoder().encode(state).write(to: fileURL, options: .atomic)
    }
}
