import Foundation

struct LocalDealsStore: Sendable {
    private let fileURL: URL

    nonisolated init(
        fileManager: FileManager = .default,
        directoryURL: URL? = nil
    ) {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = (directoryURL ?? baseURL.appendingPathComponent("BillingFlow", isDirectory: true))
            .appendingPathComponent("deals.json", isDirectory: false)
    }

    nonisolated func loadDeals() throws -> [Deal] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Deal].self, from: Data(contentsOf: fileURL))
    }

    nonisolated func saveDeals(_ deals: [Deal]) throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        try encoder.encode(deals).write(to: fileURL, options: .atomic)
    }
}
