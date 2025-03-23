import Foundation
import Combine

@MainActor
final class DocumentsListViewModel: ObservableObject {

    // MARK: - Navigation

    private let router: DocumentsRouterProtocol

    // MARK: - Data Dependencies

    private let documentsRepository: DocumentsRepositoryProtocol

    // MARK: - State

    enum State: Equatable {
        case idle
        case loading
        case loaded([BusinessDocument])
        case empty
        case error(String)
    }

    @Published private(set) var state: State = .idle

    // MARK: - Initialization

    init(
        router: DocumentsRouterProtocol,
        documentsRepository: DocumentsRepositoryProtocol
    ) {
        self.router = router
        self.documentsRepository = documentsRepository
    }

    // MARK: - Lifecycle

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
    
    // MARK: - User Actions

    func didTapCreateDocument(type: DocumentType) {
        router.showCreateDocument(type: type)
    }

    func didTapDocument(document: BusinessDocument) {
        router.showEditDocument(document: document)
    }

    // MARK: - Loading Logic

    private func performLoad() async {
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
