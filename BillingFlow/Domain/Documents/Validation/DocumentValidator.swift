import Foundation

struct DocumentValidator {

    // MARK: - Validation

    func validate(document: BusinessDocument) -> DocumentValidationResult {
        var errors: [DocumentValidationError] = []

        if document.seller.isEmpty {
            errors.append(.missingSeller)
        }

        if document.buyer.isEmpty {
            errors.append(.missingBuyer)
        }

        if document.items.isEmpty {
            errors.append(.emptyItems)
        }

        if document.number.isEmpty {
            errors.append(.missingDocumentNumber)
        }

        if document.currencyCode.isEmpty {
            errors.append(.missingCurrencyCode)
        }

        if hasItemsWithMissingTitle(in: document) {
            errors.append(.missingItemTitle)
        }

        if hasItemsWithInvalidQuantity(in: document) {
            errors.append(.invalidItemQuantity)
        }

        if hasItemsWithInvalidPrice(in: document) {
            errors.append(.invalidItemPrice)
        }

        if hasInvalidTotals(in: document) {
            errors.append(.invalidTotals)
        }

        return DocumentValidationResult(errors: errors)
    }

    // MARK: - Item Validation

    private func hasItemsWithMissingTitle(in document: BusinessDocument) -> Bool {
        document.items.contains {
            $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func hasItemsWithInvalidQuantity(in document: BusinessDocument) -> Bool {
        document.items.contains { $0.quantity <= 0 }
    }

    private func hasItemsWithInvalidPrice(in document: BusinessDocument) -> Bool {
        document.items.contains { $0.price < 0 }
    }

    // MARK: - Totals

    private func hasInvalidTotals(in document: BusinessDocument) -> Bool {
        let expectedTotals = DocumentTotals(items: document.items)
        return document.totals != expectedTotals
    }
}
