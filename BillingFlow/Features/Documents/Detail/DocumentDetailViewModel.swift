import Combine
import Foundation

@MainActor
final class DocumentDetailViewModel: ObservableObject {

    // MARK: - State

    @Published private(set) var document: BusinessDocument

    // MARK: - Dependencies

    private weak var coordinator: DocumentsCoordinatorProtocol?

    // MARK: - Initialization

    init(
        document: BusinessDocument,
        coordinator: DocumentsCoordinatorProtocol
    ) {
        self.document = document
        self.coordinator = coordinator
    }
}

// MARK: - Display State

extension DocumentDetailViewModel {
    var documentTitle: String {
        let number = document.number.trimmingCharacters(in: .whitespacesAndNewlines)

        guard number.isEmpty == false else {
            return "\(document.type.displayName) без номера"
        }

        return "\(document.type.displayName) №\(number)"
    }

    var documentSubtitle: String {
        "\(document.type.displayName) от \(AppDateFormatter.documentDateText(document.date))"
    }

    var totalText: String {
        CurrencyFormatter.amountText(
            document.totals.total,
            currencyCode: document.currencyCode
        )
    }

    var subtotalText: String {
        CurrencyFormatter.amountText(
            document.totals.subtotal,
            currencyCode: document.currencyCode
        )
    }

    var itemCountText: String {
        "\(document.totals.itemCount) \(document.totals.itemCount.itemCountWord)"
    }

    var notesText: String? {
        let notes = document.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return notes.isEmpty ? nil : notes
    }

    var canEdit: Bool {
        document.status == .draft
    }
}

// MARK: - User Actions

extension DocumentDetailViewModel {
    func didTapBack() {
        coordinator?.pop()
    }

    func didTapEdit() {
        coordinator?.showEditDocument(document: document)
    }

    func didTapDuplicate() {
        coordinator?.showDuplicateDocument(document: document)
    }

    func didTapPreview() {
        coordinator?.showPreview(document: document)
    }
}

private extension Int {
    var itemCountWord: String {
        let lastTwoDigits = self % 100
        let lastDigit = self % 10

        if (11...14).contains(lastTwoDigits) {
            return "позиций"
        }

        switch lastDigit {
        case 1:
            return "позиция"
        case 2...4:
            return "позиции"
        default:
            return "позиций"
        }
    }
}
