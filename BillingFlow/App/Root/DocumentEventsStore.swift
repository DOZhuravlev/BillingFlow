import Combine
import Foundation

@MainActor
final class DocumentEventsStore {
    private let documentsDidChangeSubject = PassthroughSubject<Void, Never>()

    var documentsDidChangePublisher: AnyPublisher<Void, Never> {
        documentsDidChangeSubject.eraseToAnyPublisher()
    }

    func sendDocumentsDidChange() {
        documentsDidChangeSubject.send()
    }
}
