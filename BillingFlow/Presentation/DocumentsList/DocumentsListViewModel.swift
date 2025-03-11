import Foundation
import Combine

@MainActor
final class DocumentsListViewModel: ObservableObject {

    // MARK: - Dependencies

    private let repository: DocumentsRepositoryProtocol

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

    init(repository: DocumentsRepositoryProtocol) {
        self.repository = repository
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

    // MARK: - Loading Logic

    private func performLoad() async {
        do {
            let documents = try await repository.fetchDocuments()

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
