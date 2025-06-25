import Combine

@MainActor
final class DealEventsStore {
    private let dealsDidChangeSubject = PassthroughSubject<Void, Never>()

    var dealsDidChangePublisher: AnyPublisher<Void, Never> {
        dealsDidChangeSubject.eraseToAnyPublisher()
    }

    func sendDealsDidChange() {
        dealsDidChangeSubject.send()
    }
}
