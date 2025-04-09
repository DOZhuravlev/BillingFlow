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
    @Published private(set) var financeMetrics: [FinanceMetric] = []
    @Published private(set) var recentDocuments: [DocumentCardItem] = []
    @Published private(set) var topOrganizations: [TopOrganizationMetric] = []

    // MARK: - Dependencies

    private weak var coordinator: HomeCoordinatorProtocol?
    private let documentsRepository: DocumentsRepositoryProtocol
    private let summaryService: FinanceSummaryServiceProtocol
    private let documentCardItemMapper: DocumentCardItemMapper

    // MARK: - Initialization

    init(
        coordinator: HomeCoordinatorProtocol,
        documentsRepository: DocumentsRepositoryProtocol,
        summaryService: FinanceSummaryServiceProtocol,
        documentCardItemMapper: DocumentCardItemMapper = DocumentCardItemMapper()
    ) {
        self.coordinator = coordinator
        self.documentsRepository = documentsRepository
        self.summaryService = summaryService
        self.documentCardItemMapper = documentCardItemMapper
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
    func didTapCreateDocument(type: DocumentType) {
        coordinator?.showCreateDocument(type: type)
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
        financeMetrics = makeFinanceMetrics(from: documents)
        recentDocuments = makeRecentDocuments(from: documents)
        topOrganizations = makeTopOrganizations(from: documents)
    }

    func makeFinanceMetrics(from documents: [BusinessDocument]) -> [FinanceMetric] {
        let summary = summaryService.makeSummary(
            documents: documents,
            filter: .all
        )

        return [
            FinanceMetric(
                title: "Получено",
                amount: CurrencyFormatter.rubleText(summary.receivedAmount),
                style: .income
            ),
            FinanceMetric(
                title: "Ожидает оплаты",
                amount: CurrencyFormatter.rubleText(summary.pendingAmount),
                style: .pending
            )
        ]
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
        financeMetrics = []
        recentDocuments = []
        topOrganizations = []
    }
}
