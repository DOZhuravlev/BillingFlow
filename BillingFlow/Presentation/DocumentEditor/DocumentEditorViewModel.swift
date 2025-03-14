import Foundation
import Combine

@MainActor
final class DocumentEditorViewModel: ObservableObject {

    // MARK: - Dependencies

    private let repository: DocumentsRepositoryProtocol
    private let draftFactory: DocumentFactory
    private let validator: DocumentValidator

    // MARK: - State

    @Published var draft: DocumentDraft
    @Published private(set) var isSaving = false
    @Published private(set) var errorMessage: String?

    // MARK: - Computed Properties

    var totals: DocumentTotals {
        draft.totals
    }

    var canSave: Bool {
        validator.validate(document: readyDocument).isValid
    }

    private var readyDocument: BusinessDocument {
        draft.asBusinessDocument(status: .ready)
    }

    // MARK: - Initialization

    init(
        type: DocumentType,
        repository: DocumentsRepositoryProtocol,
        factory: DocumentFactory,
        validator: DocumentValidator
    ) {
        self.repository = repository
        self.draftFactory = factory
        self.validator = validator
        self.draft = factory.makeEmptyDraft(type: type)
    }

    convenience init(
        type: DocumentType,
        repository: DocumentsRepositoryProtocol
    ) {
        self.init(
            type: type,
            repository: repository,
            factory: DocumentFactory(),
            validator: DocumentValidator()
        )
    }

    // MARK: - Updating Parties

    func updateSeller(_ seller: DocumentParty) {
        updateDraft { draft in
            draft.seller = seller
        }
    }

    func updateBuyer(_ buyer: DocumentParty) {
        updateDraft { draft in
            draft.buyer = buyer
        }
    }

    // MARK: - Updating Draft

    func updateNotes(_ notes: String) {
        updateDraft { draft in
            draft.notes = notes
        }
    }

    func updateDate(_ date: Date) {
        updateDraft { draft in
            draft.date = date
        }
    }

    func updateNumber(_ number: String) {
        updateDraft { draft in
            draft.number = number.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    // MARK: - Managing Items

    func addItem() {
        updateDraft { draft in
            draft.items.append(
                DocumentItem(
                    title: "",
                    quantity: 1,
                    unit: defaultUnit(for: draft.type),
                    price: 0
                )
            )
        }
    }

    // MARK: - Updating Item Fields

    func updateItemTitle(id: UUID, title: String) {
        updateDraft { draft in
            guard let index = draft.items.firstIndex(where: { $0.id == id }) else { return }
            draft.items[index].title = title
        }
    }

    func updateItemQuantity(id: UUID, quantity: Decimal) {
        updateDraft { draft in
            guard let index = draft.items.firstIndex(where: { $0.id == id }) else { return }
            draft.items[index].quantity = quantity
        }
    }

    func updateItemUnit(id: UUID, unit: String) {
        updateDraft { draft in
            guard let index = draft.items.firstIndex(where: { $0.id == id }) else { return }
            draft.items[index].unit = unit
        }
    }

    func updateItemPrice(id: UUID, price: Decimal) {
        updateDraft { draft in
            guard let index = draft.items.firstIndex(where: { $0.id == id }) else { return }
            draft.items[index].price = price
        }
    }

    // MARK: - Remove Item

    func removeItem(id: UUID) {
        updateDraft { draft in
            draft.items.removeAll(where: { $0.id == id })
        }
    }

    // MARK: - Saving

    func save() async {
        guard isSaving == false else { return }

        errorMessage = nil

        let validationResult = validator.validate(document: readyDocument)

        guard validationResult.isValid else {
            errorMessage = validationResult.errors.first?.errorDescription ?? "Не удалось сохранить документ."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try await repository.save(document: readyDocument)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Private Helpers

    private func updateDraft(_ updates: (inout DocumentDraft) -> Void) {
        updates(&draft)
        draft.updatedAt = Date()
        errorMessage = nil
    }

    private func defaultUnit(for type: DocumentType) -> String {
        switch type {
        case .deliveryNote:
            return "шт"
        case .invoice, .act:
            return ""
        }
    }
}
