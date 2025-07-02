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
    @Published private(set) var newsItems: [BillingNews] = []
    @Published private(set) var activeNews: BillingNews?
    private var documentsByID: [UUID: BusinessDocument] = [:]
    private var pendingNewsOpenRequest: AppRouteStore.NewsOpenRequest?

    // MARK: - Dependencies

    private weak var coordinator: HomeCoordinatorProtocol?
    private let documentsRepository: DocumentsRepositoryProtocol
    private let organizationsRepository: OrganizationsRepositoryProtocol
    private let newsService: NewsServiceProtocol
    private let appRouteStore: AppRouteStore?
    private let documentCardItemMapper: DocumentCardItemMapper
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        coordinator: HomeCoordinatorProtocol,
        documentsRepository: DocumentsRepositoryProtocol,
        organizationsRepository: OrganizationsRepositoryProtocol,
        newsService: NewsServiceProtocol,
        appRouteStore: AppRouteStore? = nil,
        documentEventsStore: DocumentEventsStore? = nil,
        organizationEventsStore: OrganizationEventsStore? = nil,
        documentCardItemMapper: DocumentCardItemMapper = DocumentCardItemMapper()
    ) {
        self.coordinator = coordinator
        self.documentsRepository = documentsRepository
        self.organizationsRepository = organizationsRepository
        self.newsService = newsService
        self.appRouteStore = appRouteStore
        self.documentCardItemMapper = documentCardItemMapper
        bindDocumentEvents(documentEventsStore)
        bindOrganizationEvents(organizationEventsStore)
        bindNewsRoute(appRouteStore)
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

    func bindOrganizationEvents(_ organizationEventsStore: OrganizationEventsStore?) {
        organizationEventsStore?
            .organizationsDidChangePublisher
            .sink { [weak self] in
                self?.handleDocumentsDidChange()
            }
            .store(in: &cancellables)
    }

    func bindNewsRoute(_ appRouteStore: AppRouteStore?) {
        appRouteStore?
            .$newsOpenRequest
            .sink { [weak self] request in
                guard let request else { return }
                self?.handleNewsOpenRequest(request)
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

    func didTapNews(_ news: BillingNews) {
        activeNews = news
    }

    func dismissNews() {
        activeNews = nil
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
            async let documentsTask = documentsRepository.fetchDocuments()
            async let organizationsTask = organizationsRepository.fetchOrganizations()
            async let newsTask = fetchNewsSafely()

            let documents = try await documentsTask
            let organizations = try await organizationsTask
            let news = await newsTask

            guard documents.isEmpty == false || news.isEmpty == false else {
                clearContent()
                state = .empty
                return
            }

            buildContent(documents: documents, organizations: organizations, news: news)
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
        organizations: [Organization],
        news: [BillingNews]
    ) {
        _ = organizations
        documentsByID = Dictionary(uniqueKeysWithValues: documents.map { ($0.id, $0) })
        recentDocuments = makeRecentDocuments(from: documents)
        newsItems = news
        resolvePendingNewsOpenRequest()
    }

    func makeRecentDocuments(from documents: [BusinessDocument]) -> [DocumentCardItem] {
        documents
            .sorted(by: documentComesBefore)
            .prefix(3)
            .map(documentCardItemMapper.map)
    }

    func documentComesBefore(_ lhs: BusinessDocument, _ rhs: BusinessDocument) -> Bool {
        if lhs.status == .draft, rhs.status != .draft { return true }
        if lhs.status != .draft, rhs.status == .draft { return false }
        return (lhs.updatedAt ?? lhs.date) > (rhs.updatedAt ?? rhs.date)
    }

    func fetchNewsSafely() async -> [BillingNews] {
        do {
            return try await newsService.fetchNews()
        } catch {
            return []
        }
    }

    func handleNewsOpenRequest(_ request: AppRouteStore.NewsOpenRequest) {
        pendingNewsOpenRequest = request
        if case .idle = state {
            Task { [weak self] in
                await self?.loadDocuments()
            }
        } else {
            resolvePendingNewsOpenRequest()
        }
    }

    func resolvePendingNewsOpenRequest() {
        guard let request = pendingNewsOpenRequest else { return }
        guard newsItems.isEmpty == false else { return }

        if let newsID = request.newsID {
            guard let news = newsItems.first(where: { $0.id == newsID }) else { return }
            activeNews = news
        }

        pendingNewsOpenRequest = nil
        appRouteStore?.consumeNewsOpenRequest(id: request.id)
    }

    func clearContent() {
        documentsByID = [:]
        recentDocuments = []
        newsItems = []
    }
}
