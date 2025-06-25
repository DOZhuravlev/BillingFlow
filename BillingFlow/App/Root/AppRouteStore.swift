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

    @Published private(set) var organizationProfileRequestID: UUID?
    @Published private(set) var dealCreationRequest: DealCreationRequest?
    @Published private(set) var documentCreationRequest: DocumentCreationRequest?

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
}
