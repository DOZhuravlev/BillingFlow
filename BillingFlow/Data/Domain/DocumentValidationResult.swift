import Foundation

// MARK: - Validation Error

enum DocumentValidationError: Equatable, Hashable, Sendable {
    case missingSeller
    case missingBuyer
    case emptyItems
    case invalidTotals
    case missingDocumentNumber
    case missingCurrencyCode
    case missingItemTitle
    case invalidItemQuantity
    case invalidItemPrice

    var errorDescription: String {
        switch self {
        case .missingSeller:
            return "Не заполнены данные продавца."
        case .missingBuyer:
            return "Не заполнены данные покупателя."
        case .emptyItems:
            return "Добавьте хотя бы одну позицию."
        case .invalidTotals:
            return "Итоговые суммы не совпадают с позициями документа."
        case .missingDocumentNumber:
            return "Не указан номер документа."
        case .missingCurrencyCode:
            return "Не указана валюта документа."
        case .missingItemTitle:
            return "У одной или нескольких позиций отсутствует наименование."
        case .invalidItemQuantity:
            return "Количество в позициях должно быть больше нуля."
        case .invalidItemPrice:
            return "Цена в позициях не может быть отрицательной."
        }
    }
}

// MARK: - Validation Result

struct DocumentValidationResult: Equatable, Sendable {

    let isValid: Bool
    let errors: [DocumentValidationError]

    init(errors: [DocumentValidationError] = []) {
        self.errors = errors
        self.isValid = errors.isEmpty
    }
}
