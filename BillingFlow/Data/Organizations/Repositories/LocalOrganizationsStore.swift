import Foundation

struct LocalOrganizationsStore: Sendable {

    // MARK: - Properties

    private let fileURL: URL

    // MARK: - Initialization

    nonisolated init(
        fileManager: FileManager = .default,
        directoryURL: URL? = nil
    ) {
        self.fileURL = (directoryURL ?? Self.makeRootDirectoryURL(fileManager: fileManager))
            .appendingPathComponent("organizations.json", isDirectory: false)
    }

    // MARK: - Loading

    nonisolated func loadOrganizations() throws -> [Organization] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        return try Self.makeDecoder().decode([Organization].self, from: data)
    }

    // MARK: - Saving

    nonisolated func saveOrganizations(_ organizations: [Organization]) throws {
        try ensureDirectoryExists()

        let data = try Self.makeEncoder().encode(organizations)
        try data.write(to: fileURL, options: .atomic)
    }
}

// MARK: - Private Helpers

private extension LocalOrganizationsStore {
    nonisolated func ensureDirectoryExists() throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: directoryURL.path) == false {
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
        }
    }

    nonisolated static func makeRootDirectoryURL(fileManager: FileManager) -> URL {
        let baseURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first

        guard let baseURL else {
            preconditionFailure("Unable to resolve a writable organizations directory.")
        }

        return baseURL.appendingPathComponent("BillingFlow", isDirectory: true)
    }

    nonisolated static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    nonisolated static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
