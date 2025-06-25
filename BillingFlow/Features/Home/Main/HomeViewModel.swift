import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - State

    enum State: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case error(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var recentDocuments: [DocumentCardItem] = []
    @Published private(set) var topOrganizations: [TopOrganizationMetric] = []
    private var documentsByID: [UUID: BusinessDocument] = [:]

    // MARK: - Dependencies

    private weak var coordinator: HomeCoordinatorProtocol?
    private let documentsRepository: DocumentsRepositoryProtocol
    private let organizationsRepository: OrganizationsRepositoryProtocol
    private let documentCardItemMapper: DocumentCardItemMapper
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        coordinator: HomeCoordinatorProtocol,
        documentsRepository: DocumentsRepositoryProtocol,
        organizationsRepository: OrganizationsRepositoryProtocol,
        documentEventsStore: DocumentEventsStore? = nil,
        documentCardItemMapper: DocumentCardItemMapper = DocumentCardItemMapper()
    ) {
        self.coordinator = coordinator
        self.documentsRepository = documentsRepository
        self.organizationsRepository = organizationsRepository
        self.documentCardItemMapper = documentCardItemMapper
        bindDocumentEvents(documentEventsStore)
    }
}

// MARK: - Events

private extension HomeViewModel {
    func bindDocumentEvents(_ documentEventsStore: DocumentEventsStore?) {
        documentEventsStore?
            .documentsDidChangePublisher
            .sink { [weak self] in
                self?.handleDocumentsDidChange()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Lifecycle

extension HomeViewModel {
    func loadDocumentsIfNeeded() async {
        guard case .idle = state else { return }
        await loadDocuments()
    }

    func loadDocuments() async {
        guard case .loading = state else {
            state = .loading
            await performLoad()
            return
        }
    }

    func reload() async {
        state = .loading
        await performLoad()
    }
}

// MARK: - User Actions

extension HomeViewModel {
    func didTapNotifications() {
        coordinator?.showNotifications()
    }

    func didTapCreateDocument(type: DocumentType) {
        coordinator?.showCreateDocument(type: type)
    }

    func didTapCreateDeal(type: DealType) {
        coordinator?.showCreateDeal(type: type)
    }

    func didTapDocument(id: UUID) {
        guard let document = documentsByID[id] else { return }
        coordinator?.showDocument(document)
    }

    func didTapDocument(document: BusinessDocument) {
        coordinator?.showDocument(document)
    }

    func didTapOrganization(_ organization: TopOrganizationMetric) {
        coordinator?.showOrganization(organization)
    }

    func handleDocumentsDidChange() {
        Task { [weak self] in
            await self?.reload()
        }
    }
}

// MARK: - Loading Logic

private extension HomeViewModel {
    func performLoad() async {
        do {
            let documents = try await documentsRepository.fetchDocuments()
            let organizations = try await organizationsRepository.fetchOrganizations()

            guard documents.isEmpty == false else {
                clearContent()
                state = .empty
                return
            }

            buildContent(documents: documents, organizations: organizations)
            state = .loaded
        } catch {
            clearContent()
            state = .error(error.localizedDescription)
        }
    }
}

// MARK: - Content Building

private extension HomeViewModel {
    func buildContent(
        documents: [BusinessDocument],
        organizations: [Organization]
    ) {
        documentsByID = Dictionary(uniqueKeysWithValues: documents.map { ($0.id, $0) })
        recentDocuments = makeRecentDocuments(from: documents)
        topOrganizations = makeTopOrganizations(
            organizations: organizations,
            documents: documents
        )
    }

    func makeRecentDocuments(from documents: [BusinessDocument]) -> [DocumentCardItem] {
        documents
            .sorted(by: documentComesBefore)
            .prefix(3)
            .map(documentCardItemMapper.map)
    }

    func makeTopOrganizations(
        organizations: [Organization],
        documents: [BusinessDocument]
    ) -> [TopOrganizationMetric] {
        let organizationsByKey = organizations.reduce(into: [String: Organization]()) { result, organization in
            result[organization.matchingKey] = organization
        }
        var metricsByKey: [String: (
            organization: Organization,
            count: Int,
            total: Decimal,
            currencyCode: String,
            documents: [BusinessDocument]
        )] = [:]

        for document in documents where document.status != .draft && document.buyer.isEmpty == false {
            let organization = Organization(party: document.buyer, role: .buyer)
            let key = organization.matchingKey
            let storedOrganization = organizationsByKey[key] ?? organization

            if var metric = metricsByKey[key] {
                metric.count += 1
                metric.total += document.totals.total
                metric.documents.append(document)
                metricsByKey[key] = metric
            } else {
                metricsByKey[key] = (
                    organization: storedOrganization,
                    count: 1,
                    total: document.totals.total,
                    currencyCode: document.currencyCode,
                    documents: [document]
                )
            }
        }

        return metricsByKey.values
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.total > rhs.total
                }
                return lhs.count > rhs.count
            }
            .prefix(3)
            .map { metric in
                TopOrganizationMetric(
                    id: metric.organization.matchingKey,
                    name: metric.organization.party.displayName,
                    documentCount: metric.count,
                    totalAmount: CurrencyFormatter.amountText(
                        metric.total,
                        currencyCode: metric.currencyCode
                    ),
                    party: metric.organization.party,
                    documents: metric.documents.sorted { $0.date > $1.date }
                )
            }
    }

    func documentComesBefore(_ lhs: BusinessDocument, _ rhs: BusinessDocument) -> Bool {
        if lhs.status == .draft, rhs.status != .draft { return true }
        if lhs.status != .draft, rhs.status == .draft { return false }
        return (lhs.updatedAt ?? lhs.date) > (rhs.updatedAt ?? rhs.date)
    }

    func clearContent() {
        documentsByID = [:]
        recentDocuments = []
        topOrganizations = []
    }
}
