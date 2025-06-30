import Foundation

nonisolated struct DocumentsSyncState: Codable, Sendable {
    var revisions: [UUID: Int64] = [:]
    var pendingUpserts: Set<UUID> = []
    var pendingDeletes: Set<UUID> = []
}

nonisolated struct DocumentsSyncStateStore: Sendable {
    private let fileURL: URL
    init(directoryURL: URL) { fileURL = directoryURL.appendingPathComponent("documents-sync.json") }

    func load() throws -> DocumentsSyncState {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return DocumentsSyncState() }
        return try JSONDecoder().decode(DocumentsSyncState.self, from: Data(contentsOf: fileURL))
    }

    func save(_ state: DocumentsSyncState) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(state).write(to: fileURL, options: .atomic)
    }
}
