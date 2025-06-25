import Foundation

struct DocumentFactory {

    private let idProvider: () -> UUID
    private let dateProvider: () -> Date

    init(
        idProvider: @escaping () -> UUID = UUID.init,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.idProvider = idProvider
        self.dateProvider = dateProvider
    }

    func makeEmptyDraft(type: DocumentType, dealID: UUID? = nil) -> DocumentDraft {
        let now = dateProvider()

        return DocumentDraft(
            id: idProvider(),
            type: type,
            date: now,
            seller: DocumentParty(),
            buyer: DocumentParty(),
            items: [],
            notes: "",
            currencyCode: "RUB",
            sourceDocumentID: nil,
            dealID: dealID,
            updatedAt: now
        )
    }

    func makeDuplicateDraft(from source: BusinessDocument) -> DocumentDraft {
        let now = dateProvider()

        return DocumentDraft(
            id: idProvider(),
            type: source.type,
            number: "",
            date: now,
            seller: source.seller,
            buyer: source.buyer,
            items: makeItemCopies(from: source.items),
            notes: source.notes,
            currencyCode: source.currencyCode,
            sourceDocumentID: source.id,
            dealID: source.dealID,
            updatedAt: now
        )
    }
}

private extension DocumentFactory {
    func makeItemCopies(from items: [DocumentItem]) -> [DocumentItem] {
        items.map { item in
            DocumentItem(
                id: idProvider(),
                title: item.title,
                quantity: item.quantity,
                unit: item.unit,
                price: item.price,
                vatRate: item.vatRate
            )
        }
    }
}
