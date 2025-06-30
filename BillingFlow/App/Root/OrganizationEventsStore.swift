import Combine

@MainActor
final class OrganizationEventsStore {
    private let organizationsDidChangeSubject = PassthroughSubject<Void, Never>()

    var organizationsDidChangePublisher: AnyPublisher<Void, Never> {
        organizationsDidChangeSubject.eraseToAnyPublisher()
    }

    func sendOrganizationsDidChange() {
        organizationsDidChangeSubject.send()
    }
}
