import Foundation

struct DocumentFactory {

    // MARK: - Draft Creation

    func makeEmptyDraft(type: DocumentType) -> DocumentDraft {
        let now = Date()

        return DocumentDraft(
            type: type,
            date: now,
            seller: DocumentParty(),
            buyer: DocumentParty(),
            items: [],
            notes: "",
            currencyCode: "RUB",
            sourceDocumentID: nil,
            updatedAt: now
        )
    }
}
