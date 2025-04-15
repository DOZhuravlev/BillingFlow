import Foundation

@MainActor
protocol DocumentsCoordinatorProtocol: AnyObject {
    func start()
    func showDetail(document: BusinessDocument)
    func showCreateDocument(type: DocumentType)
    func showDuplicateDocument(document: BusinessDocument)
    func showEditDocument(document: BusinessDocument)
    func showPreview(document: BusinessDocument)
    func showPreview(
        document: BusinessDocument,
        saveAction: @escaping () async -> Void,
        signAndSendAction: @escaping () async -> Void
    )
    func finishDocumentFlowAfterShare()
    func finishDocumentFlowAfterSave()
    func dismiss()
    func pop()
}

extension DocumentsCoordinatorProtocol {
    func showPreview(
        document: BusinessDocument,
        saveAction: @escaping () async -> Void,
        signAndSendAction: @escaping () async -> Void
    ) {
        showPreview(document: document)
    }

    func finishDocumentFlowAfterSave() {
        finishDocumentFlowAfterShare()
    }
}
