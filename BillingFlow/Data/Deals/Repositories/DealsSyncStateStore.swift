import Foundation

nonisolated struct DealsSyncState: Codable, Sendable {
    var revisions: [UUID: Int64] = [:]
    var pendingUpserts: Set<UUID> = []
    var pendingDeletes: Set<UUID> = []
}

nonisolated struct DealsSyncStateStore: Sendable {
    private let fileURL: URL

    init(directoryURL: URL) {
        fileURL = directoryURL.appendingPathComponent("deals-sync.json")
    }

    func load() throws -> DealsSyncState {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return DealsSyncState() }
        return try JSONDecoder().decode(DealsSyncState.self, from: Data(contentsOf: fileURL))
    }

    func save(_ state: DealsSyncState) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try JSONEncoder().encode(state).write(to: fileURL, options: .atomic)
    }
}
