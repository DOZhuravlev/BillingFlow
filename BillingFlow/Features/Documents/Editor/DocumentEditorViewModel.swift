import Combine
import Foundation

@MainActor
final class DocumentEditorViewModel: ObservableObject {

    enum Mode {
        case create(DocumentType)
        case duplicate(BusinessDocument)
        case edit(BusinessDocument)
    }

    enum Step: Int, CaseIterable, Identifiable {
        case type
        case seller
        case buyer
        case details
        case items
        case notes
        case review

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .type:
                return "Тип"
            case .seller:
                return "Продавец"
            case .buyer:
                return "Покупатель"
            case .details:
                return "Реквизиты"
            case .items:
                return "Позиции"
            case .notes:
                return "Комментарий"
            case .review:
                return "Проверка"
            }
        }
    }

    struct OrganizationOption: Identifiable, Hashable {
        let id: String
        let party: DocumentParty
        let roleTitle: String
        let documentCount: Int

        var subtitle: String {
            let taxText = party.taxID.isEmpty ? "ИНН не указан" : "ИНН \(party.taxID)"
            if documentCount > 0 {
                return "\(roleTitle) · \(taxText) · \(documentCount) док."
            }
            return "\(roleTitle) · \(taxText)"
        }
    }

    // MARK: - State

    @Published var draft: DocumentDraft
    @Published var currentStep: Step = .type
    @Published private(set) var organizationOptions: [OrganizationOption] = []
    @Published private(set) var recentInvoiceTemplates: [BusinessDocument] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var isSending = false
    @Published private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let mode: Mode
    private weak var coordinator: DocumentsCoordinatorProtocol?
    private let documentsRepository: DocumentsRepositoryProtocol
    private let organizationsRepository: OrganizationsRepositoryProtocol
    private let documentEventsStore: DocumentEventsStore
    private let documentFactory: DocumentFactory
    private let documentValidator: DocumentValidator

    // MARK: - Initialization

    init(
        mode: Mode,
        router: DocumentsCoordinatorProtocol,
        documentsRepository: DocumentsRepositoryProtocol,
        organizationsRepository: OrganizationsRepositoryProtocol,
        documentEventsStore: DocumentEventsStore,
        documentFactory: DocumentFactory,
        documentValidator: DocumentValidator
    ) {
        self.mode = mode
        self.coordinator = router
        self.documentsRepository = documentsRepository
        self.organizationsRepository = organizationsRepository
        self.documentEventsStore = documentEventsStore
        self.documentFactory = documentFactory
        self.documentValidator = documentValidator
        self.draft = Self.makeInitialDraft(
            mode: mode,
            documentFactory: documentFactory
        )

        if draft.type == .invoice {
            self.draft = Self.loadAutosavedDraft(key: autosaveKey) ?? draft
        }

        if draft.items.isEmpty {
            addItem()
        }
    }
}

// MARK: - Derived State

extension DocumentEditorViewModel {
    var steps: [Step] {
        Step.allCases
    }

    var progress: Double {
        Double(currentStep.rawValue + 1) / Double(Step.allCases.count)
    }

    var totals: DocumentTotals {
        draft.totals
    }

    var selectedVATRate: Decimal? {
        draft.items.first?.vatRate
    }

    var canMoveForward: Bool {
        switch currentStep {
        case .type:
            return draft.type == .invoice
        case .seller:
            return draft.seller.isEmpty == false
        case .buyer:
            return draft.buyer.isEmpty == false
        case .details:
            return draft.number.isEmpty == false
        case .items:
            return draft.items.isEmpty == false && draft.items.allSatisfy(\.isValid)
        case .notes:
            return true
        case .review:
            return canSave
        }
    }

    var canSave: Bool {
        documentValidator.validate(document: readyDocument).isValid
    }

    var isEditing: Bool {
        if case .edit = mode {
            return true
        }
        return false
    }

    var navigationTitle: String {
        isEditing ? "Редактирование счета" : "Новый счет"
    }
}

// MARK: - Loading

extension DocumentEditorViewModel {
    func onAppear() async {
        guard isLoading == false else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let documents = try await documentsRepository.fetchDocuments()
            let storedOrganizations = try await organizationsRepository.fetchOrganizations()
            organizationOptions = Self.makeOrganizationOptions(
                storedOrganizations: storedOrganizations,
                documents: documents
            )
            recentInvoiceTemplates = documents
                .filter { $0.type == .invoice }
                .sorted { $0.date > $1.date }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Navigation

extension DocumentEditorViewModel {
    func goForward() {
        guard canMoveForward else { return }
        guard let nextStep = Step(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = nextStep
        autosaveDraft()
    }

    func goBack() {
        guard let previousStep = Step(rawValue: currentStep.rawValue - 1) else {
            coordinator?.pop()
            return
        }
        currentStep = previousStep
        autosaveDraft()
    }

    func goToStep(_ step: Step) {
        currentStep = step
    }

    func didTapClose() {
        autosaveDraft()
        coordinator?.pop()
    }

    func didTapPreview() {
        coordinator?.showPreview(
            document: readyDocument,
            saveAction: { [weak self] in
                await self?.didTapSave()
            },
            signAndSendAction: { [weak self] in
                await self?.didTapSignAndSend()
            }
        )
    }
}

// MARK: - Template Actions

extension DocumentEditorViewModel {
    func useTemplate(_ document: BusinessDocument) {
        draft = documentFactory.makeDuplicateDraft(from: document)
        draft.type = .invoice
        draft.updatedAt = Date()
        currentStep = .seller
        autosaveDraft()
    }
}

// MARK: - Party Actions

extension DocumentEditorViewModel {
    func selectSeller(_ party: DocumentParty) {
        updateDraft { $0.seller = party }
    }

    func selectBuyer(_ party: DocumentParty) {
        updateDraft { $0.buyer = party }
    }

    func updateSeller(_ seller: DocumentParty) {
        updateDraft { $0.seller = seller }
    }

    func updateBuyer(_ buyer: DocumentParty) {
        updateDraft { $0.buyer = buyer }
    }
}

// MARK: - Document Metadata Actions

extension DocumentEditorViewModel {
    func updateNotes(_ notes: String) {
        updateDraft { $0.notes = notes }
    }

    func updateDate(_ date: Date) {
        updateDraft { $0.date = date }
    }

    func updateCurrencyCode(_ currencyCode: String) {
        updateDraft {
            $0.currencyCode = currencyCode
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
        }
    }

    func updateNumber(_ number: String) {
        updateDraft {
            $0.number = number.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    func updateVATRate(_ vatRate: Decimal?) {
        updateDraft { draft in
            for index in draft.items.indices {
                draft.items[index].vatRate = vatRate
            }
        }
    }
}

// MARK: - Item Collection Actions

extension DocumentEditorViewModel {
    func addItem() {
        updateDraft { draft in
            draft.items.append(
                DocumentItem(
                    title: "",
                    quantity: 1,
                    unit: "шт",
                    price: 0,
                    vatRate: draft.items.first?.vatRate
                )
            )
        }
    }

    func removeItem(id: UUID) {
        let currentVATRate = selectedVATRate
        updateDraft { draft in
            draft.items.removeAll(where: { $0.id == id })
            if draft.items.isEmpty {
                draft.items.append(DocumentItem(vatRate: currentVATRate))
            }
        }
    }
}

// MARK: - Item Field Editing Actions

extension DocumentEditorViewModel {
    func updateItemTitle(id: UUID, title: String) {
        updateItem(id: id) { $0.title = title }
    }

    func updateItemQuantity(id: UUID, quantity: Decimal) {
        updateItem(id: id) { $0.quantity = quantity }
    }

    func updateItemUnit(id: UUID, unit: String) {
        updateItem(id: id) { $0.unit = unit }
    }

    func updateItemPrice(id: UUID, price: Decimal) {
        updateItem(id: id) { $0.price = price }
    }
}

// MARK: - Save Flow

extension DocumentEditorViewModel {
    func didTapSave() async {
        await saveDocument(shouldSend: false)
    }

    func didTapSignAndSend() async {
        await saveDocument(shouldSend: true)
    }
}

private extension DocumentEditorViewModel {
    func saveDocument(shouldSend: Bool) async {
        guard isSaving == false, isSending == false else { return }

        if shouldSend {
            isSending = true
        } else {
            isSaving = true
        }
        defer {
            isSaving = false
            isSending = false
        }

        errorMessage = nil
        let validationResult = documentValidator.validate(document: readyDocument)

        guard validationResult.isValid else {
            errorMessage = validationResult.errors.first?.errorDescription ?? "Не удалось сохранить документ."
            return
        }

        do {
            try await organizationsRepository.upsert(party: draft.seller, role: .seller)
            try await organizationsRepository.upsert(party: draft.buyer, role: .buyer)
            try await documentsRepository.save(document: readyDocument)
            documentEventsStore.sendDocumentsDidChange()
            clearAutosavedDraft()
            coordinator?.finishDocumentFlowAfterSave()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Mapping

private extension DocumentEditorViewModel {
    var readyDocument: BusinessDocument {
        draft.asBusinessDocument(status: .ready)
    }

    static func makeInitialDraft(
        mode: Mode,
        documentFactory: DocumentFactory
    ) -> DocumentDraft {
        switch mode {
        case .create(let type):
            return documentFactory.makeEmptyDraft(type: type)

        case .duplicate(let document):
            return documentFactory.makeDuplicateDraft(from: document)

        case .edit(let document):
            return makeDraft(from: document)
        }
    }

    static func makeDraft(from document: BusinessDocument) -> DocumentDraft {
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

    static func makeOrganizationOptions(
        storedOrganizations: [Organization],
        documents: [BusinessDocument]
    ) -> [OrganizationOption] {
        var parties: [String: (party: DocumentParty, role: Organization.Role, count: Int, updatedAt: Date)] = [:]

        for organization in storedOrganizations where organization.party.isEmpty == false {
            parties[organization.matchingKey] = (
                organization.party,
                organization.role,
                0,
                organization.updatedAt
            )
        }

        for document in documents {
            merge(
                party: document.seller,
                role: .seller,
                date: document.date,
                into: &parties
            )
            merge(
                party: document.buyer,
                role: .buyer,
                date: document.date,
                into: &parties
            )
        }

        return parties.values
            .sorted { $0.updatedAt > $1.updatedAt }
            .map { value in
                let organization = Organization(party: value.party, role: value.role)
                return OrganizationOption(
                    id: organization.matchingKey,
                    party: value.party,
                    roleTitle: value.role.title,
                    documentCount: value.count
                )
            }
    }

    static func merge(
        party: DocumentParty,
        role: Organization.Role,
        date: Date,
        into parties: inout [String: (party: DocumentParty, role: Organization.Role, count: Int, updatedAt: Date)]
    ) {
        guard party.isEmpty == false else { return }

        let organization = Organization(party: party, role: role, updatedAt: date)
        if var existing = parties[organization.matchingKey] {
            existing.party = party
            existing.count += 1
            existing.updatedAt = max(existing.updatedAt, date)
            existing.role = existing.role == role ? role : .mixed
            parties[organization.matchingKey] = existing
        } else {
            parties[organization.matchingKey] = (party, role, 1, date)
        }
    }
}

// MARK: - Draft Persistence

private extension DocumentEditorViewModel {
    var autosaveKey: String {
        switch mode {
        case .create:
            return "billingflow.invoiceWizard.autosave.create"
        case .duplicate:
            return "billingflow.invoiceWizard.autosave.duplicate.\(draft.sourceDocumentID?.uuidString ?? draft.id.uuidString)"
        case .edit(let document):
            return "billingflow.invoiceWizard.autosave.edit.\(document.id.uuidString)"
        }
    }

    func autosaveDraft() {
        guard draft.type == .invoice else { return }

        do {
            let data = try JSONEncoder.autosaveEncoder.encode(draft)
            UserDefaults.standard.set(data, forKey: autosaveKey)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearAutosavedDraft() {
        UserDefaults.standard.removeObject(forKey: autosaveKey)
    }

    static func loadAutosavedDraft(key: String) -> DocumentDraft? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder.autosaveDecoder.decode(DocumentDraft.self, from: data)
    }
}

// MARK: - Draft Mutation Helpers

private extension DocumentEditorViewModel {
    func updateDraft(_ updates: (inout DocumentDraft) -> Void) {
        updates(&draft)
        draft.updatedAt = Date()
        errorMessage = nil
        autosaveDraft()
    }

    func updateItem(id: UUID, updates: (inout DocumentItem) -> Void) {
        updateDraft { draft in
            guard let index = draft.items.firstIndex(where: { $0.id == id }) else { return }
            updates(&draft.items[index])
        }
    }
}

private extension JSONEncoder {
    static var autosaveEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var autosaveDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
