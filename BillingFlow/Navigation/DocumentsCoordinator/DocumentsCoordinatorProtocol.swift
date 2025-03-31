import Foundation

@MainActor
protocol DocumentsCoordinatorProtocol: AnyObject {
    func start()
    func showCreateDocument(type: DocumentType)
    func showEditDocument(document: BusinessDocument)
    func showPreview(document: BusinessDocument)
    func finishDocumentFlowAfterShare()
    func dismiss()
    func pop()
}
