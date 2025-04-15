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
    @Published private(set) var latestDocument: BusinessDocument?

    // MARK: - Dependencies

    private weak var coordinator: HomeCoordinatorProtocol?
    private let documentsRepository: DocumentsRepositoryProtocol
    private let documentCardItemMapper: DocumentCardItemMapper
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        coordinator: HomeCoordinatorProtocol,
        documentsRepository: DocumentsRepositoryProtocol,
        documentEventsStore: DocumentEventsStore? = nil,
        documentCardItemMapper: DocumentCardItemMapper = DocumentCardItemMapper()
    ) {
        self.coordinator = coordinator
        self.documentsRepository = documentsRepository
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

// MARK: - Derived State

extension HomeViewModel {
    var canDuplicateLatestDocument: Bool {
        latestDocument != nil
    }
}

// MARK: - User Actions

extension HomeViewModel {
    func didTapCreateDocument(type: DocumentType) {
        coordinator?.showCreateDocument(type: type)
    }

    func didTapDuplicateLatestDocument() {
        guard let latestDocument else { return }
        coordinator?.showDuplicateDocument(latestDocument)
    }

    func didTapDocument(document: BusinessDocument) {
        coordinator?.showDocument(document)
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

            guard documents.isEmpty == false else {
                clearContent()
                state = .empty
                return
            }

            buildContent(from: documents)
            state = .loaded
        } catch {
            clearContent()
            state = .error(error.localizedDescription)
        }
    }
}

// MARK: - Content Building

private extension HomeViewModel {
    func buildContent(from documents: [BusinessDocument]) {
        latestDocument = documents.max(by: { $0.date < $1.date })
        recentDocuments = makeRecentDocuments(from: documents)
        topOrganizations = makeTopOrganizations(from: documents)
    }

    func makeRecentDocuments(from documents: [BusinessDocument]) -> [DocumentCardItem] {
        documents
            .sorted { $0.date > $1.date }
            .prefix(3)
            .map(documentCardItemMapper.map)
    }

    func makeTopOrganizations(from documents: [BusinessDocument]) -> [TopOrganizationMetric] {
        // TODO: Replace with real grouping.
        [
            TopOrganizationMetric(
                id: "mock-alfa",
                name: "ООО Альфа",
                documentCount: 8,
                totalAmount: "185 000 ₽"
            ),
            TopOrganizationMetric(
                id: "mock-vector",
                name: "ООО Вектор",
                documentCount: 5,
                totalAmount: "92 500 ₽"
            ),
            TopOrganizationMetric(
                id: "mock-petrov",
                name: "ИП Петров П.П.",
                documentCount: 3,
                totalAmount: "74 000 ₽"
            )
        ]
    }

    func clearContent() {
        latestDocument = nil
        recentDocuments = []
        topOrganizations = []
    }
}
