import Combine
import Foundation

@MainActor
final class DealsListViewModel: ObservableObject {
    struct Item: Identifiable {
        let deal: Deal
        let status: DealStatus
        let documents: [BusinessDocument]

        var id: UUID { deal.id }
    }

    enum State: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case error(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var items: [Item] = []

    private weak var coordinator: DealsCoordinatorProtocol?
    private let dealsRepository: DealsRepositoryProtocol
    private let documentsRepository: DocumentsRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    init(
        coordinator: DealsCoordinatorProtocol,
        dealsRepository: DealsRepositoryProtocol,
        documentsRepository: DocumentsRepositoryProtocol,
        dealEventsStore: DealEventsStore,
        documentEventsStore: DocumentEventsStore
    ) {
        self.coordinator = coordinator
        self.dealsRepository = dealsRepository
        self.documentsRepository = documentsRepository

        dealEventsStore.dealsDidChangePublisher
            .merge(with: documentEventsStore.documentsDidChangePublisher)
            .sink { [weak self] in
                Task { await self?.reload() }
            }
            .store(in: &cancellables)
    }

    func loadIfNeeded() async {
        guard state == .idle else { return }
        await reload()
    }

    func reload() async {
        state = .loading
        do {
            let deals = try await dealsRepository.fetchDeals()
            let documents = try await documentsRepository.fetchDocuments()
            items = deals.map { deal in
                let linkedDocuments = documents.filter { $0.dealID == deal.id }
                return Item(
                    deal: deal,
                    status: deal.effectiveStatus(documents: linkedDocuments),
                    documents: linkedDocuments
                )
            }
            state = items.isEmpty ? .empty : .loaded
        } catch {
            items = []
            state = .error(error.localizedDescription)
        }
    }

    func didTapDeal(_ deal: Deal) {
        coordinator?.showDeal(deal)
    }

    func didTapCreate() {
        coordinator?.showCreateDeal(type: .services)
    }
}
