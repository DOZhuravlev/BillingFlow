import Foundation

@MainActor
protocol HomeCoordinatorProtocol: AnyObject {
    func start()

    func showNotifications()
    func showProfile()

    func showCreateDocument(type: DocumentType)
    func showDuplicateDocument(_ document: BusinessDocument)

    func showDocument(_ document: BusinessDocument)
    func showDocumentPreview(_ document: BusinessDocument)
    func showAllDocuments()

    func showOrganization(_ organization: UUID)
    func showAllOrganizations()

    func showFinanceDetails(filter: HomeFinanceFilter)

    func dismiss()
    func pop()
}

enum HomeFinanceFilter: Equatable {
    case paidDocuments
    case pendingDocuments
}
