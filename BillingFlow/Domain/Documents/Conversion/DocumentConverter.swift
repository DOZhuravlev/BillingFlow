import Foundation

struct DocumentConverter {

    private let idProvider: () -> UUID
    private let dateProvider: () -> Date

    init(
        idProvider: @escaping () -> UUID = UUID.init,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.idProvider = idProvider
        self.dateProvider = dateProvider
    }

    // MARK: - Public API

    func duplicate(_ document: BusinessDocument) -> BusinessDocument {
        DocumentFactory(
            idProvider: idProvider,
            dateProvider: dateProvider
        )
        .makeDuplicateDraft(from: document)
        .asBusinessDocument(status: .draft)
    }

    func convertToAct(from document: BusinessDocument) -> BusinessDocument {
        makeDocumentCopy(from: document, targetType: .act)
    }

    func convertToDeliveryNote(from document: BusinessDocument) -> BusinessDocument {
        makeDocumentCopy(from: document, targetType: .deliveryNote)
    }

    private func makeDocumentCopy(
        from source: BusinessDocument,
        targetType: DocumentType
    ) -> BusinessDocument {
        BusinessDocument(
            id: idProvider(),
            type: targetType,
            number: "",
            date: dateProvider(),
            seller: source.seller,
            buyer: source.buyer,
            items: makeItemCopies(from: source.items),
            notes: source.notes,
            currencyCode: source.currencyCode,
            status: .draft
        )
    }

    private func makeItemCopies(from items: [DocumentItem]) -> [DocumentItem] {
        items.map { item in
            DocumentItem(
                id: idProvider(),
                title: item.title,
                quantity: item.quantity,
                unit: item.unit,
                price: item.price
            )
        }
    }
}
