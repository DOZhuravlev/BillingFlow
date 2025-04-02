import Foundation

struct LocalDocumentsStore: Sendable {

    // MARK: - Properties

    private let fileURL: URL

    // MARK: - Initialization

    nonisolated init(fileManager: FileManager = .default) {
        self.fileURL = Self.makeFileURL(fileManager: fileManager)
    }

    // MARK: - Loading Documents

    nonisolated func loadDocuments() throws -> [BusinessDocument] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        return try Self.makeDecoder().decode([BusinessDocument].self, from: data)
    }

    // MARK: - Saving Documents

    nonisolated func saveDocuments(_ documents: [BusinessDocument]) throws {
        try ensureDirectoryExists()

        let data = try Self.makeEncoder().encode(documents)
        try data.write(to: fileURL, options: .atomic)
    }

    // MARK: - Private Helpers

    nonisolated private func ensureDirectoryExists() throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: directoryURL.path) == false {
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
        }
    }

    nonisolated private static func makeFileURL(fileManager: FileManager) -> URL {
        let baseURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first

        guard let baseURL else {
            preconditionFailure("Unable to resolve a writable documents directory.")
        }

        return baseURL
            .appendingPathComponent("BillingFlow", isDirectory: true)
            .appendingPathComponent("documents.json", isDirectory: false)
    }

    nonisolated private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    nonisolated private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
