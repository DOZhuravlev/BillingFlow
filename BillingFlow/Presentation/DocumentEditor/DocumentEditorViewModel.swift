import Foundation
import Combine

@MainActor
final class DocumentEditorViewModel: ObservableObject {

    // MARK: - Navigation

    private let router: DocumentsRouterProtocol

    // MARK: - Data Dependencies

    private let documentsRepository: DocumentsRepositoryProtocol
    private let documentFactory: DocumentFactory
    private let documentValidator: DocumentValidator

    // MARK: - Editing Mode

    enum Mode {
        case create(DocumentType)
        case edit(BusinessDocument)
    }

    private let mode: Mode

    // MARK: - Editable State

    @Published var draft: DocumentDraft
    @Published private(set) var isSaving = false
    @Published private(set) var errorMessage: String?

    // MARK: - Derived UI State

    var totals: DocumentTotals {
        draft.totals
    }

    var canSave: Bool {
        documentValidator.validate(document: readyDocument).isValid
    }

    var isEditing: Bool {
        switch mode {
        case .create:
            return false
        case .edit:
            return true
        }
    }

    var navigationTitle: String {
        switch draft.type {
        case .invoice:
            return isEditing ? "Редактирование счета" : "Новый счет"
        case .act:
            return isEditing ? "Редактирование акта" : "Новый акт"
        case .deliveryNote:
            return isEditing ? "Редактирование накладной" : "Новая накладная"
        }
    }

    // MARK: - Initialization

    init(
        mode: Mode,
        router: DocumentsRouterProtocol,
        documentsRepository: DocumentsRepositoryProtocol,
        documentFactory: DocumentFactory,
        documentValidator: DocumentValidator
    ) {
        self.mode = mode
        self.router = router
        self.documentsRepository = documentsRepository
        self.documentFactory = documentFactory
        self.documentValidator = documentValidator

        switch mode {
        case .create(let type):
            self.draft = documentFactory.makeEmptyDraft(type: type)
        case .edit(let document):
            self.draft = Self.makeDraft(from: document)
        }
    }

    // MARK: - Counterparty Editing Actions

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

    // MARK: - Document Metadata Actions

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

    // MARK: - Item Collection Actions

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

    func removeItem(id: UUID) {
        updateDraft { draft in
            draft.items.removeAll(where: { $0.id == id })
        }
    }

    // MARK: - Item Field Editing Actions

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

    // MARK: - Save Flow Actions

    func didTapSave() async {
        guard isSaving == false else { return }

        errorMessage = nil

        let validationResult = documentValidator.validate(document: readyDocument)

        guard validationResult.isValid else {
            errorMessage = validationResult.errors.first?.errorDescription ?? "Не удалось сохранить документ."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try await documentsRepository.save(document: readyDocument)
            router.showPreview(document: readyDocument)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Navigation Actions

    func didTapPreview() {
        router.showPreview(document: readyDocument)
    }

    func didTapClose() {
        router.dismiss()
    }

    // MARK: - Document Mapping

    private var readyDocument: BusinessDocument {
        draft.asBusinessDocument(status: .ready)
    }

    private static func makeDraft(from document: BusinessDocument) -> DocumentDraft {
        DocumentDraft(
            id: document.id,
            type: document.type,
            number: document.number,
            date: document.date,
            seller: document.seller,
            buyer: document.buyer,
            items: document.items,
            notes: document.notes,
            currencyCode: document.currencyCode,
            updatedAt: Date()
        )
    }

    // MARK: - Draft Mutation Helpers

    private func updateDraft(_ updates: (inout DocumentDraft) -> Void) {
        updates(&draft)
        draft.updatedAt = Date()
        errorMessage = nil
    }

    // MARK: - Draft Defaults

    private func defaultUnit(for type: DocumentType) -> String {
        switch type {
        case .deliveryNote:
            return "шт"
        case .invoice, .act:
            return ""
        }
    }
}
