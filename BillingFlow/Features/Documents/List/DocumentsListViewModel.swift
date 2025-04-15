import Combine
import Foundation

@MainActor
final class DocumentsListViewModel: ObservableObject {

    // MARK: - State

    enum State: Equatable {
        case idle
        case loading
        case loaded([BusinessDocument])
        case empty
        case error(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var filter = DocumentsFilter()

    // MARK: - Dependencies

    private weak var coordinator: DocumentsCoordinatorProtocol?
    private let documentsRepository: DocumentsRepositoryProtocol
    private let listGrouper: DocumentsListGrouper
    private let documentItemMapper: DocumentsListItemMapper
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        coordinator: DocumentsCoordinatorProtocol,
        documentsRepository: DocumentsRepositoryProtocol,
        documentEventsStore: DocumentEventsStore? = nil,
        listGrouper: DocumentsListGrouper = DocumentsListGrouper(),
        documentItemMapper: DocumentsListItemMapper = DocumentsListItemMapper()
    ) {
        self.coordinator = coordinator
        self.documentsRepository = documentsRepository
        self.listGrouper = listGrouper
        self.documentItemMapper = documentItemMapper
        bindDocumentEvents(documentEventsStore)
    }
}

// MARK: - Events

private extension DocumentsListViewModel {
    func bindDocumentEvents(_ documentEventsStore: DocumentEventsStore?) {
        documentEventsStore?
            .documentsDidChangePublisher
            .sink { [weak self] in
                self?.handleDocumentsDidChange()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Display State

extension DocumentsListViewModel {
    var selectedCounterpartyTitle: String {
        filter.counterpartyName ?? "Все контрагенты"
    }

    var hasAdvancedFilters: Bool {
        filter.hasAdvancedFilters
    }

    var hasActiveFilters: Bool {
        filter.hasActiveFilters
    }

    var activeFilterChips: [DocumentsFilterChipItem] {
        filter.activeChips
    }

    var availableCounterparties: [DocumentsCounterpartyFilterItem] {
        DocumentsCounterpartyFilterItem.makeItems(from: loadedDocuments)
    }

    var documentSections: [DocumentsListSection] {
        listGrouper
            .groupByMonth(filteredDocuments)
            .map { section in
                DocumentsListSection(
                    key: section.key,
                    title: section.title,
                    items: section.documents.map { document in
                        DocumentsListSectionItem(
                            document: document,
                            item: documentItemMapper.map(document)
                        )
                    }
                )
            }
    }
}

// MARK: - Lifecycle

extension DocumentsListViewModel {
    func loadDocumentsIfNeeded() async {
        guard case .idle = state else { return }
        await loadDocuments()
    }

    // MARK: - Loading Documents

    func loadDocuments() async {
        if case .loading = state { return }

        state = .loading
        await performLoad()
    }

    func reload() async {
        await loadDocuments()
    }

    // MARK: - Data Refresh

    func handleDocumentsDidChange() {
        Task {
            await reload()
        }
    }
}

// MARK: - User Actions

extension DocumentsListViewModel {
    func didTapCreateDocument(type: DocumentType) {
        coordinator?.showCreateDocument(type: type)
    }

    func didTapDocument(document: BusinessDocument) {
        coordinator?.showDetail(document: document)
    }
}

// MARK: - Filter Actions

extension DocumentsListViewModel {
    func applyFilter(_ filter: DocumentsFilter) {
        self.filter = filter
    }

    func selectCounterparty(_ counterparty: DocumentsCounterpartyFilterItem?) {
        filter.counterpartyName = counterparty?.name
    }

    func resetAdvancedFilters() {
        filter.resetAdvancedFilters()
    }

    func resetAllFilters() {
        filter.resetAll()
    }

    func removeFilterChip(_ chip: DocumentsFilterChipItem) {
        switch chip.kind {
        case .type:
            filter.type = .all

        case .status:
            filter.status = .all

        case .period:
            filter.period = .all
        }
    }
}

// MARK: - Loading Logic

private extension DocumentsListViewModel {
    func performLoad() async {
        do {
            let documents = try await documentsRepository.fetchDocuments()

            if documents.isEmpty {
                state = .empty
            } else {
                state = .loaded(documents)
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}

// MARK: - Documents

private extension DocumentsListViewModel {
    var loadedDocuments: [BusinessDocument] {
        guard case .loaded(let documents) = state else {
            return []
        }
        return documents
    }

    var filteredDocuments: [BusinessDocument] {
        loadedDocuments
            .filter { filter.matches($0) }
            .sorted { $0.date > $1.date }
    }
}
