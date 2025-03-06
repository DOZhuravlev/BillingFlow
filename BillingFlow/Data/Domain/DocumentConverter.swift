import Foundation

struct DocumentConverter {

    // MARK: - Duplication

    func duplicate(document: BusinessDocument) -> BusinessDocument {
        makeDocumentCopy(from: document, targetType: document.type)
    }

    // MARK: - Conversion

    func convertToAct(from document: BusinessDocument) -> BusinessDocument {
        makeDocumentCopy(from: document, targetType: .act)
    }

    func convertToDeliveryNote(from document: BusinessDocument) -> BusinessDocument {
        makeDocumentCopy(from: document, targetType: .deliveryNote)
    }

    // MARK: - Document Building
    
    private func makeDocumentCopy(
        from source: BusinessDocument,
        targetType: DocumentType
    ) -> BusinessDocument {
        let now = Date()

        return BusinessDocument(
            id: UUID(),
            type: targetType,
            number: "",
            date: now,
            seller: source.seller,
            buyer: source.buyer,
            items: copyItemsForNewDocument(source.items),
            notes: source.notes,
            currencyCode: source.currencyCode,
            status: .draft
        )
    }

    // MARK: - Item Copying

    private func copyItemsForNewDocument(_ items: [DocumentItem]) -> [DocumentItem] {
        items.map { item in
            DocumentItem(
                id: UUID(),
                title: item.title,
                quantity: item.quantity,
                unit: item.unit,
                price: item.price
            )
        }
    }
}
