import Foundation

@MainActor
protocol DocumentsCoordinatorProtocol: AnyObject {
    func start()
    func showDetail(document: BusinessDocument)
    func showCreateDocument(type: DocumentType)
    func showCreateDocument(type: DocumentType, buyer: DocumentParty)
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
    func showCreateDocument(type: DocumentType, buyer: DocumentParty) {
        showCreateDocument(type: type)
    }

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
