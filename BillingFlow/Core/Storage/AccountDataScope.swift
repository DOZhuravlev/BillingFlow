import Foundation

nonisolated struct AccountDataScope: Hashable, Sendable {
    let userID: String?
    let directoryURL: URL
    let generation: Int

    var cacheKey: String {
        "\(identityKey):\(generation)"
    }

    var identityKey: String {
        userID.map { "user:\($0)" } ?? "guest"
    }
}

actor AccountDataScopeProvider {
    private enum Constants {
        static let filenames = [
            "documents.json",
            "deals.json",
            "organizations.json",
            "organizations-sync.json",
            "documents-sync.json",
            "deals-sync.json"
        ]
        static let ownerFilename = "account-scope-owner.txt"
    }

    private let authSession: AuthSession
    private let fileManager: FileManager
    private let rootDirectoryURL: URL
    private var preparedScopeKeys: Set<String> = []
    private var storageGeneration = 0

    init(authSession: AuthSession, fileManager: FileManager = .default) {
        self.authSession = authSession
        self.fileManager = fileManager
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.rootDirectoryURL = baseURL.appendingPathComponent("BillingFlow", isDirectory: true)
    }

    func currentScope() async throws -> AccountDataScope {
        let userID = await authSession.currentUserID()
        let directoryURL: URL
        if let userID {
            directoryURL = rootDirectoryURL
                .appendingPathComponent("Accounts", isDirectory: true)
                .appendingPathComponent(safePathComponent(userID), isDirectory: true)
        } else {
            directoryURL = rootDirectoryURL
                .appendingPathComponent("Accounts", isDirectory: true)
                .appendingPathComponent("guest", isDirectory: true)
        }

        let scope = AccountDataScope(
            userID: userID,
            directoryURL: directoryURL,
            generation: storageGeneration
        )
        if try prepareIfNeeded(scope) {
            storageGeneration += 1
        }
        return AccountDataScope(
            userID: userID,
            directoryURL: directoryURL,
            generation: storageGeneration
        )
    }
}

private extension AccountDataScopeProvider {
    func prepareIfNeeded(_ scope: AccountDataScope) throws -> Bool {
        guard preparedScopeKeys.contains(scope.identityKey) == false else { return false }
        try fileManager.createDirectory(at: scope.directoryURL, withIntermediateDirectories: true)
        var didMoveFiles = false

        if let userID = scope.userID {
            let claimedOwnerID = claimedOwnerID()
            if claimedOwnerID == nil || claimedOwnerID == userID {
                didMoveFiles = try migrateFiles(from: rootDirectoryURL, to: scope.directoryURL) || didMoveFiles
                let guestURL = rootDirectoryURL
                    .appendingPathComponent("Accounts", isDirectory: true)
                    .appendingPathComponent("guest", isDirectory: true)
                didMoveFiles = try migrateFiles(from: guestURL, to: scope.directoryURL) || didMoveFiles
                try Data(userID.utf8).write(to: ownerMarkerURL, options: .atomic)
            }
        } else {
            if claimedOwnerID() == nil {
                didMoveFiles = try migrateFiles(from: rootDirectoryURL, to: scope.directoryURL)
            }
        }

        preparedScopeKeys.insert(scope.identityKey)
        return didMoveFiles
    }

    func migrateFiles(from sourceDirectory: URL, to targetDirectory: URL) throws -> Bool {
        guard sourceDirectory != targetDirectory else { return false }
        var didMoveFiles = false
        for filename in Constants.filenames {
            let sourceURL = sourceDirectory.appendingPathComponent(filename)
            let targetURL = targetDirectory.appendingPathComponent(filename)
            guard fileManager.fileExists(atPath: sourceURL.path),
                  fileManager.fileExists(atPath: targetURL.path) == false else { continue }
            try fileManager.moveItem(at: sourceURL, to: targetURL)
            didMoveFiles = true
        }
        return didMoveFiles
    }

    var ownerMarkerURL: URL {
        rootDirectoryURL.appendingPathComponent(Constants.ownerFilename)
    }

    func claimedOwnerID() -> String? {
        if let data = try? Data(contentsOf: ownerMarkerURL),
           let value = String(data: data, encoding: .utf8),
           value.isEmpty == false {
            return value
        }

        let legacyStateURL = rootDirectoryURL.appendingPathComponent("organizations-sync.json")
        guard let data = try? Data(contentsOf: legacyStateURL),
              let state = try? JSONDecoder().decode(OrganizationsSyncState.self, from: data) else {
            return nil
        }
        return state.ownerUserID
    }

    func safePathComponent(_ value: String) -> String {
        value.map { character in
            character.isLetter || character.isNumber || character == "-" ? character : "_"
        }
        .reduce(into: "") { $0.append($1) }
    }
}
