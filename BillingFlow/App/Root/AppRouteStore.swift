import Combine
import Foundation

@MainActor
final class AppRouteStore: ObservableObject {

    struct DealCreationRequest: Identifiable, Equatable {
        let id: UUID
        let type: DealType
    }

    struct DocumentCreationRequest: Identifiable, Equatable {
        let id: UUID
        let type: DocumentType
    }

    struct DocumentOpenRequest: Identifiable, Equatable {
        let id: UUID
        let documentID: UUID
    }

    struct NewsOpenRequest: Identifiable, Equatable {
        let id: UUID
        let newsID: UUID?
    }

    @Published private(set) var organizationProfileRequestID: UUID?
    @Published private(set) var dealCreationRequest: DealCreationRequest?
    @Published private(set) var documentCreationRequest: DocumentCreationRequest?
    @Published private(set) var documentOpenRequest: DocumentOpenRequest?
    @Published private(set) var newsOpenRequest: NewsOpenRequest?

    func openOrganizationProfile() {
        organizationProfileRequestID = UUID()
    }

    func consumeOrganizationProfileRequest(id: UUID) {
        guard organizationProfileRequestID == id else { return }
        organizationProfileRequestID = nil
    }

    func openDealCreation(type: DealType) {
        dealCreationRequest = DealCreationRequest(id: UUID(), type: type)
    }

    func consumeDealCreationRequest(id: UUID) {
        guard dealCreationRequest?.id == id else { return }
        dealCreationRequest = nil
    }

    func openDocumentCreation(type: DocumentType) {
        documentCreationRequest = DocumentCreationRequest(id: UUID(), type: type)
    }

    func consumeDocumentCreationRequest(id: UUID) {
        guard documentCreationRequest?.id == id else { return }
        documentCreationRequest = nil
    }

    func openDocument(id documentID: UUID) {
        documentOpenRequest = DocumentOpenRequest(id: UUID(), documentID: documentID)
    }

    func consumeDocumentOpenRequest(id: UUID) {
        guard documentOpenRequest?.id == id else { return }
        documentOpenRequest = nil
    }

    func openNews(id newsID: UUID?) {
        newsOpenRequest = NewsOpenRequest(id: UUID(), newsID: newsID)
    }

    func consumeNewsOpenRequest(id: UUID) {
        guard newsOpenRequest?.id == id else { return }
        newsOpenRequest = nil
    }
}
