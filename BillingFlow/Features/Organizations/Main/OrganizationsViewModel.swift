import Combine
import Foundation

@MainActor
final class OrganizationsViewModel: ObservableObject {

    struct Item: Identifiable, Hashable {
        let id: String
        let party: DocumentParty
        let roleTitle: String
        let documentCount: Int
        let documents: [BusinessDocument]

        var name: String {
            party.displayName.isEmpty ? "Без названия" : party.displayName
        }

        var taxIDText: String {
            party.taxID.isEmpty ? "ИНН не указан" : "ИНН \(party.taxID)"
        }

        var documentsCountText: String {
            "\(documentCount) \(Self.documentWord(for: documentCount))"
        }

        var initials: String {
            name
                .split(separator: " ")
                .prefix(2)
                .compactMap(\.first)
                .map(String.init)
                .joined()
                .uppercased()
        }
    }

    // MARK: - State

    @Published private(set) var items: [Item] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let organizationsRepository: OrganizationsRepositoryProtocol
    private let documentsRepository: DocumentsRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        organizationsRepository: OrganizationsRepositoryProtocol,
        documentsRepository: DocumentsRepositoryProtocol,
        documentEventsStore: DocumentEventsStore? = nil
    ) {
        self.organizationsRepository = organizationsRepository
        self.documentsRepository = documentsRepository
        bindDocumentEvents(documentEventsStore)
    }
}

// MARK: - Events

private extension OrganizationsViewModel {
    func bindDocumentEvents(_ documentEventsStore: DocumentEventsStore?) {
        documentEventsStore?
            .documentsDidChangePublisher
            .sink { [weak self] in
                self?.handleDocumentsDidChange()
            }
            .store(in: &cancellables)
    }

    func handleDocumentsDidChange() {
        Task {
            await load()
        }
    }
}

// MARK: - Loading

extension OrganizationsViewModel {
    func load() async {
        guard isLoading == false else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let organizations = try await organizationsRepository.fetchOrganizations()
            let documents = try await documentsRepository.fetchDocuments()
            items = Self.makeItems(
                storedOrganizations: organizations,
                documents: documents
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Mapping

private extension OrganizationsViewModel {
    static func makeItems(
        storedOrganizations: [Organization],
        documents: [BusinessDocument]
    ) -> [Item] {
        var values: [String: (
            party: DocumentParty,
            role: Organization.Role,
            count: Int,
            updatedAt: Date,
            documents: [BusinessDocument]
        )] = [:]

        for organization in storedOrganizations where organization.party.isEmpty == false && organization.role != .seller {
            values[organization.matchingKey] = (
                organization.party,
                organization.role,
                0,
                organization.updatedAt,
                []
            )
        }

        for document in documents where document.status != .draft {
            merge(
                party: document.buyer,
                role: .buyer,
                date: document.date,
                document: document,
                into: &values
            )
        }

        return values.map { key, value in
            Item(
                id: key,
                party: value.party,
                roleTitle: value.role.title,
                documentCount: value.count,
                documents: value.documents.sorted { $0.date > $1.date }
            )
        }
        .sorted { lhs, rhs in
            if lhs.documentCount == rhs.documentCount {
                return lhs.name < rhs.name
            }
            return lhs.documentCount > rhs.documentCount
        }
    }

    static func merge(
        party: DocumentParty,
        role: Organization.Role,
        date: Date,
        document: BusinessDocument,
        into values: inout [String: (
            party: DocumentParty,
            role: Organization.Role,
            count: Int,
            updatedAt: Date,
            documents: [BusinessDocument]
        )]
    ) {
        guard party.isEmpty == false else { return }

        let organization = Organization(party: party, role: role, updatedAt: date)
        if var existing = values[organization.matchingKey] {
            existing.party = party
            existing.role = existing.role == role ? role : .mixed
            existing.count += 1
            existing.updatedAt = max(existing.updatedAt, date)
            existing.documents.append(document)
            values[organization.matchingKey] = existing
        } else {
            values[organization.matchingKey] = (party, role, 1, date, [document])
        }
    }
}

private extension OrganizationsViewModel.Item {
    static func documentWord(for count: Int) -> String {
        let mod10 = count % 10
        let mod100 = count % 100

        if mod10 == 1 && mod100 != 11 {
            return "документ"
        }

        if (2...4).contains(mod10) && !(12...14).contains(mod100) {
            return "документа"
        }

        return "документов"
    }
}
