import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {

    @Published private(set) var state: State = .idle
    @Published private(set) var financeMetrics: [FinanceMetric] = []
    @Published private(set) var recentDocuments: [DocumentCardItem] = []
    @Published private(set) var topOrganizations: [TopOrganizationMetric] = []

    // MARK: - Navigation

    private let router: DocumentsRouterProtocol

    // MARK: - Data Dependencies

    private let documentsRepository: DocumentsRepositoryProtocol
    private let summaryService: FinanceSummaryServiceProtocol
    private let documentCardItemMapper: DocumentCardItemMapper

    // MARK: - State

    enum State: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case error(String)
    }

    // MARK: - Initialization

    init(
        router: DocumentsRouterProtocol,
        documentsRepository: DocumentsRepositoryProtocol,
        summaryService: FinanceSummaryServiceProtocol,
        documentCardItemMapper: DocumentCardItemMapper = DocumentCardItemMapper()
    ) {
        self.router = router
        self.documentsRepository = documentsRepository
        self.summaryService = summaryService
        self.documentCardItemMapper = documentCardItemMapper
    }

    // MARK: - Lifecycle

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

    // MARK: - User Actions

    func didTapCreateDocument(type: DocumentType) {
        router.showCreateDocument(type: type)
    }

    func didTapDocument(document: BusinessDocument) {
        router.showEditDocument(document: document)
    }

    func handleDocumentsDidChange() {
         Task { [weak self] in
             await self?.reload()
         }
     }
}

private extension HomeViewModel {

    private func performLoad() async {
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

       private func buildContent(from documents: [BusinessDocument]) {
           financeMetrics = makeFinanceMetrics(from: documents)
           recentDocuments = makeRecentDocuments(from: documents)
           topOrganizations = makeTopOrganizations(from: documents)
       }

       private func makeFinanceMetrics(from documents: [BusinessDocument]) -> [FinanceMetric] {
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

    private func makeRecentDocuments(from documents: [BusinessDocument]) -> [DocumentCardItem] {
        documents
            .sorted { $0.date > $1.date }
            .prefix(3)
            .map(documentCardItemMapper.map)
    }

    private func makeTopOrganizations(from documents: [BusinessDocument]) -> [TopOrganizationMetric] {

           // TODO: Replace with real grouping

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

       private func clearContent() {
           financeMetrics = []
           recentDocuments = []
           topOrganizations = []
       }
}
