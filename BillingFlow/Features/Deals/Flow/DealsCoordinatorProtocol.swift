import Foundation

@MainActor
protocol DealsCoordinatorProtocol: AnyObject {
    func showCreateDeal(type: DealType)
    func showDeal(_ deal: Deal)
    func showDocument(_ document: BusinessDocument)
    func createDocument(type: DocumentType, for deal: Deal)
    func finishDealCreation(_ deal: Deal)
    func pop()
}
