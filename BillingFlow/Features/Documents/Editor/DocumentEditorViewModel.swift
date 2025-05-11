import Combine
import Foundation

@MainActor
final class DocumentEditorViewModel: ObservableObject {

    enum Mode {
        case create(DocumentType)
        case duplicate(BusinessDocument)
        case edit(BusinessDocument)
    }

    enum PartySearchTarget {
        case seller
        case buyer
    }

    enum Step: Int, CaseIterable, Identifiable {
        case start
        case seller
        case buyer
        case details
        case items
        case notes
        case review

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .start:
                return "Старт"
            case .seller:
                return "Реквизиты"
            case .buyer:
                return "Плательщик"
            case .details:
                return "Реквизиты"
            case .items:
                return "Позиции"
            case .notes:
                return "Оплата"
            case .review:
                return "Проверка"
            }
        }
    }

    struct OrganizationOption: Identifiable, Hashable {
        let id: String
        let party: DocumentParty
        let role: Organization.Role
        let bankAccounts: [OrganizationBankAccount]
        let defaultBankAccountID: UUID?
        let isDefault: Bool
        let roleTitle: String
        let documentCount: Int

        var subtitle: String {
            let taxText = party.taxID.isEmpty ? "ИНН не указан" : "ИНН \(party.taxID)"
            if documentCount > 0 {
                return "\(roleTitle) · \(taxText) · \(documentCount) док."
            }
            return "\(roleTitle) · \(taxText)"
        }

        var defaultBankAccount: OrganizationBankAccount? {
            bankAccounts.first { $0.id == defaultBankAccountID }
                ?? bankAccounts.first { $0.isDefault }
                ?? bankAccounts.first
        }
    }

    struct VATBreakdownLine: Identifiable {
        let rate: Decimal
        let amount: Decimal

        var id: String {
            "vat-\(rate)"
        }
    }

    // MARK: - State

    @Published var draft: DocumentDraft
    @Published var currentStep: Step = .start
    @Published private(set) var organizationOptions: [OrganizationOption] = []
    @Published var organizationSearchQuery = ""
    @Published private(set) var organizationSearchResults: [OrganizationSuggestion] = []
    @Published private(set) var isSearchingOrganizations = false
    @Published private(set) var organizationSearchErrorMessage: String?
    @Published private(set) var recentDocumentTemplates: [BusinessDocument] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var isSending = false
    @Published private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let mode: Mode
    private weak var coordinator: DocumentsCoordinatorProtocol?
    private let documentsRepository: DocumentsRepositoryProtocol
    private let organizationsRepository: OrganizationsRepositoryProtocol
    private let organizationSearchService: OrganizationSearchServiceProtocol
    private let appRouteStore: AppRouteStore
    private let documentEventsStore: DocumentEventsStore
    private let documentFactory: DocumentFactory
    private let documentValidator: DocumentValidator
    private var loadedDocuments: [BusinessDocument] = []
    private var organizationSearchTask: Task<Void, Never>?
    private var activeOrganizationSearchTarget: PartySearchTarget?

    // MARK: - Initialization

    init(
        mode: Mode,
        router: DocumentsCoordinatorProtocol,
        documentsRepository: DocumentsRepositoryProtocol,
        organizationsRepository: OrganizationsRepositoryProtocol,
        organizationSearchService: OrganizationSearchServiceProtocol,
        appRouteStore: AppRouteStore,
        documentEventsStore: DocumentEventsStore,
        documentFactory: DocumentFactory,
        documentValidator: DocumentValidator
    ) {
        self.mode = mode
        self.coordinator = router
        self.documentsRepository = documentsRepository
        self.organizationsRepository = organizationsRepository
        self.organizationSearchService = organizationSearchService
        self.appRouteStore = appRouteStore
        self.documentEventsStore = documentEventsStore
        self.documentFactory = documentFactory
        self.documentValidator = documentValidator
        self.draft = Self.makeInitialDraft(
            mode: mode,
            documentFactory: documentFactory
        )

        self.draft = Self.loadAutosavedDraft(key: autosaveKey) ?? draft

        Self.normalizeItems(in: &draft)
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

    var canMoveForward: Bool {
        switch currentStep {
        case .start:
            return true
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
        isEditing ? "Редактирование \(documentKindName)" : "Новый \(documentKindName)"
    }

    var documentKindName: String {
        switch draft.type {
        case .invoice:
            return "счет"
        case .act:
            return "акт"
        case .deliveryNote:
            return "счет-фактура"
        }
    }

    var startStepTitle: String {
        switch draft.type {
        case .invoice:
            return "Новый счет"
        case .act:
            return "Новый акт"
        case .deliveryNote:
            return "Новая счет-фактура"
        }
    }

    var startStepSubtitle: String {
        switch draft.type {
        case .invoice:
            return "Можно заполнить с нуля или взять за основу прошлый счет."
        case .act:
            return "Можно заполнить с нуля или взять за основу прошлый акт."
        case .deliveryNote:
            return "Можно заполнить с нуля или взять за основу прошлую счет-фактуру."
        }
    }

    var templatesTitle: String {
        switch draft.type {
        case .invoice:
            return "Создать на основе прошлого счета"
        case .act:
            return "Создать на основе прошлого акта"
        case .deliveryNote:
            return "Создать на основе прошлой счет-фактуры"
        }
    }

    var freshDocumentTitle: String {
        switch draft.type {
        case .invoice:
            return "Создать новый счет"
        case .act:
            return "Создать новый акт"
        case .deliveryNote:
            return "Создать новую счет-фактуру"
        }
    }

    var freshDocumentSubtitle: String {
        switch draft.type {
        case .invoice:
            return "Продавец, покупатель, реквизиты, позиции и НДС."
        case .act:
            return "Исполнитель, заказчик, реквизиты и выполненные работы."
        case .deliveryNote:
            return "Продавец, получатель, реквизиты, позиции и НДС."
        }
    }

    var documentIconName: String {
        switch draft.type {
        case .invoice:
            return "doc.text.fill"
        case .act:
            return "checklist.checked"
        case .deliveryNote:
            return "building.columns.fill"
        }
    }

    var isFreshDocumentSelected: Bool {
        draft.sourceDocumentID == nil
    }

    func isTemplateSelected(_ document: BusinessDocument) -> Bool {
        draft.sourceDocumentID == document.id
    }

    var sellerStepTitle: String {
        switch draft.type {
        case .invoice, .deliveryNote:
            return "Реквизиты вашей организации"
        case .act:
            return "Реквизиты исполнителя"
        }
    }

    var sellerStepSubtitle: String {
        switch draft.type {
        case .invoice, .deliveryNote:
            return "Эти данные попадут в документ и подскажут плательщику, куда отправить оплату."
        case .act:
            return "Выберите свою организацию и банковский счет для оплаты работ."
        }
    }

    var buyerStepTitle: String {
        switch draft.type {
        case .invoice:
            return "Кто оплачивает счет"
        case .act:
            return "Кто оплачивает работы"
        case .deliveryNote:
            return "Кто оплачивает счет-фактуру"
        }
    }

    var buyerStepSubtitle: String {
        switch draft.type {
        case .invoice:
            return "Выберите плательщика из недавних контрагентов или найдите организацию по ИНН."
        case .act:
            return "Укажите заказчика, который принимает работы и будет связан с документом."
        case .deliveryNote:
            return "Выберите плательщика или получателя для счет-фактуры."
        }
    }

    var detailsStepTitle: String {
        switch draft.type {
        case .invoice:
            return "Реквизиты счета"
        case .act:
            return "Реквизиты акта"
        case .deliveryNote:
            return "Реквизиты счет-фактуры"
        }
    }

    var detailsStepSubtitle: String {
        switch draft.type {
        case .invoice:
            return "Укажите номер и дату документа."
        case .act:
            return "Номер и дату можно поправить вручную, позиции пойдут в акт выполненных работ."
        case .deliveryNote:
            return "Укажите номер и дату документа."
        }
    }

    var numberFieldTitle: String {
        switch draft.type {
        case .invoice:
            return "Номер счета"
        case .act:
            return "Номер акта"
        case .deliveryNote:
            return "Номер счет-фактуры"
        }
    }

    var dateFieldTitle: String {
        switch draft.type {
        case .invoice:
            return "Дата"
        case .act, .deliveryNote:
            return "Дата"
        }
    }

    var showsVATSelector: Bool {
        switch draft.type {
        case .invoice, .deliveryNote:
            return true
        case .act:
            return false
        }
    }

    var vatBreakdownLines: [VATBreakdownLine] {
        let orderedRates: [Decimal] = [10, 20]

        return orderedRates.compactMap { rate in
            let amount = draft.items
                .filter { $0.vatRate == rate }
                .reduce(Decimal.zero) { partialResult, item in
                    partialResult + item.vatAmount
                }

            guard amount > 0 else { return nil }
            return VATBreakdownLine(rate: rate, amount: amount)
        }
    }

    var itemsStepTitle: String {
        switch draft.type {
        case .invoice:
            return "Позиции счета"
        case .act:
            return "Работы и услуги"
        case .deliveryNote:
            return "Позиции счет-фактуры"
        }
    }

    var itemsStepSubtitle: String {
        switch draft.type {
        case .invoice:
            return "Укажите наименование, количество и цену. НДС можно выбрать отдельно для каждой позиции."
        case .act:
            return "Укажите выполненные работы или услуги, количество, единицу и стоимость."
        case .deliveryNote:
            return "Укажите товары или услуги. НДС можно выбрать отдельно для каждой позиции."
        }
    }

    var itemTitleLabel: String {
        switch draft.type {
        case .invoice:
            return "Название услуги или товара"
        case .act:
            return "Название работы или услуги"
        case .deliveryNote:
            return "Наименование товара или услуги"
        }
    }

    var itemTitlePlaceholder: String {
        switch draft.type {
        case .invoice:
            return "Услуга или товар"
        case .act:
            return "Работа или услуга"
        case .deliveryNote:
            return "Товар или услуга"
        }
    }

    var reviewStepTitle: String {
        switch draft.type {
        case .invoice:
            return "Проверьте счет"
        case .act:
            return "Проверьте акт"
        case .deliveryNote:
            return "Проверьте счет-фактуру"
        }
    }

    var reviewStepSubtitle: String {
        "Все ключевые параметры собраны в короткий экран перед сохранением."
    }

    var sellerReviewTitle: String {
        draft.type == .act ? "Исполнитель" : "Продавец"
    }

    var buyerReviewTitle: String {
        switch draft.type {
        case .invoice:
            return "Покупатель"
        case .act:
            return "Заказчик"
        case .deliveryNote:
            return "Получатель"
        }
    }

    var sellerOrganizationOptions: [OrganizationOption] {
        organizationOptions.filter { option in
            option.role == .seller || option.role == .mixed
        }
    }

    var buyerOrganizationOptions: [OrganizationOption] {
        organizationOptions.filter { option in
            option.role == .buyer || option.role == .mixed
        }
    }

    var selectedSellerBankAccounts: [OrganizationBankAccount] {
        selectedSellerOrganizationOption?.bankAccounts ?? []
    }

    var selectedSellerOrganizationOption: OrganizationOption? {
        let currentOrganization = Organization(party: draft.seller, role: .seller)
        return sellerOrganizationOptions.first { $0.id == currentOrganization.matchingKey }
    }

    func isSelectedSellerBankAccount(_ account: OrganizationBankAccount) -> Bool {
        draft.seller.bankName == account.bankName &&
        draft.seller.bankAccount == account.bankAccount &&
        draft.seller.bankCode == account.bankCode
    }

    var selectedBuyerOrganizationOption: OrganizationOption? {
        let currentOrganization = Organization(party: draft.buyer, role: .buyer)
        return buyerOrganizationOptions.first { $0.id == currentOrganization.matchingKey }
    }

    func title(for step: Step) -> String {
        switch step {
        case .start:
            return "Старт"
        case .seller:
            return draft.type == .act ? "Исполнитель" : "Продавец"
        case .buyer:
            switch draft.type {
            case .invoice:
                return "Покупатель"
            case .act:
                return "Заказчик"
            case .deliveryNote:
                return "Получатель"
            }
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

// MARK: - Loading

extension DocumentEditorViewModel {
    func onAppear() async {
        guard isLoading == false else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let documents = try await documentsRepository.fetchDocuments()
            let storedOrganizations = try await organizationsRepository.fetchOrganizations()
            loadedDocuments = documents
            organizationOptions = Self.makeOrganizationOptions(
                storedOrganizations: storedOrganizations,
                documents: documents
            )
            applyDefaultSellerIfNeeded(from: storedOrganizations)
            updateRecentDocumentTemplates()
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
    func useFreshDocument() {
        let type = draft.type
        let seller = draft.seller
        draft = documentFactory.makeEmptyDraft(type: type)
        draft.seller = seller
        Self.normalizeItems(in: &draft)
        updateRecentDocumentTemplates()
        autosaveDraft()
    }

    func useTemplate(_ document: BusinessDocument) {
        draft = documentFactory.makeDuplicateDraft(from: document)
        draft.updatedAt = Date()
        Self.normalizeItems(in: &draft)
        updateRecentDocumentTemplates()
        autosaveDraft()
    }
}

// MARK: - Party Actions

extension DocumentEditorViewModel {
    func activateOrganizationSearch(target: PartySearchTarget) {
        guard activeOrganizationSearchTarget != target else { return }
        activeOrganizationSearchTarget = target
        resetOrganizationSearch()
    }

    func updateOrganizationSearchQuery(_ query: String) {
        organizationSearchQuery = query
        organizationSearchErrorMessage = nil
        organizationSearchTask?.cancel()

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= 3 else {
            organizationSearchResults = []
            isSearchingOrganizations = false
            return
        }

        isSearchingOrganizations = true
        organizationSearchTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 450_000_000)
                await self?.performOrganizationSearch(query: trimmedQuery)
            } catch {
                await self?.handleCancelledOrganizationSearch()
            }
        }
    }

    func selectOrganizationSuggestion(_ suggestion: OrganizationSuggestion, target: PartySearchTarget) {
        switch target {
        case .seller:
            selectSeller(suggestion.party)
        case .buyer:
            selectBuyer(suggestion.party)
        }

        resetOrganizationSearch()
    }

    func resetOrganizationSearch() {
        organizationSearchTask?.cancel()
        organizationSearchTask = nil
        organizationSearchQuery = ""
        organizationSearchResults = []
        organizationSearchErrorMessage = nil
        isSearchingOrganizations = false
    }

    func selectSeller(_ party: DocumentParty) {
        updateDraft { $0.seller = party }
    }

    func selectSellerOrganization(_ option: OrganizationOption) {
        var party = option.party

        if let account = option.defaultBankAccount {
            party = account.apply(to: party)
        }

        selectSeller(party)
    }

    func selectSellerBankAccount(_ account: OrganizationBankAccount) {
        updateDraft { draft in
            draft.seller = account.apply(to: draft.seller)
        }
    }

    func selectBuyer(_ party: DocumentParty) {
        updateDraft { $0.buyer = party }
    }

    func resetBuyerSelection() {
        updateDraft { $0.buyer = DocumentParty() }
    }

    func updateSeller(_ seller: DocumentParty) {
        updateDraft { $0.seller = seller }
    }

    func openOrganizationProfile() {
        coordinator?.pop()
        appRouteStore.openOrganizationProfile()
    }

    func updateBuyer(_ buyer: DocumentParty) {
        updateDraft { $0.buyer = buyer }
    }
}

// MARK: - Organization Search

private extension DocumentEditorViewModel {
    func performOrganizationSearch(query: String) async {
        guard Task.isCancelled == false else { return }

        do {
            let results = try await organizationSearchService.searchOrganizations(query: query)
            guard Task.isCancelled == false else { return }
            organizationSearchResults = results
            organizationSearchErrorMessage = nil
        } catch {
            guard Task.isCancelled == false else { return }
            organizationSearchResults = []
            organizationSearchErrorMessage = error.localizedDescription
        }

        isSearchingOrganizations = false
    }

    func handleCancelledOrganizationSearch() {
        if organizationSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 {
            isSearchingOrganizations = false
        }
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

    func updateItemVATRate(id: UUID, vatRate: Decimal?) {
        updateItem(id: id) { $0.vatRate = vatRate }
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
                    unit: Self.defaultUnit(for: draft.type),
                    price: 0,
                    vatRate: draft.items.last?.vatRate
                )
            )
        }
    }

    func removeItem(id: UUID) {
        updateDraft { draft in
            draft.items.removeAll(where: { $0.id == id })
            if draft.items.isEmpty {
                draft.items.append(DocumentItem(unit: Self.defaultUnit(for: draft.type)))
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
            try await documentsRepository.save(document: readyDocument)
            try await organizationsRepository.upsert(party: draft.seller, role: .seller)
            try await organizationsRepository.upsert(party: draft.buyer, role: .buyer)
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
        var parties: [String: (
            party: DocumentParty,
            role: Organization.Role,
            count: Int,
            updatedAt: Date,
            bankAccounts: [OrganizationBankAccount],
            defaultBankAccountID: UUID?,
            isDefault: Bool
        )] = [:]

        for organization in storedOrganizations where organization.party.isEmpty == false {
            parties[organization.matchingKey] = (
                organization.party,
                organization.role,
                0,
                organization.updatedAt,
                organization.normalizedBankAccounts,
                organization.defaultBankAccountID,
                organization.isDefault
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
                    role: value.role,
                    bankAccounts: value.bankAccounts,
                    defaultBankAccountID: value.defaultBankAccountID,
                    isDefault: value.isDefault,
                    roleTitle: value.role.title,
                    documentCount: value.count
                )
            }
    }

    func updateRecentDocumentTemplates() {
        recentDocumentTemplates = loadedDocuments
            .filter { $0.type == draft.type }
            .sorted { $0.date > $1.date }
    }

    func applyDefaultSellerIfNeeded(from organizations: [Organization]) {
        guard draft.seller.isEmpty else { return }

        let defaultSeller = organizations.first { organization in
            organization.party.isEmpty == false && organization.role == .seller && organization.isDefault
        } ?? organizations.first { organization in
            organization.party.isEmpty == false && organization.isDefault
        } ?? organizations.first { organization in
            organization.party.isEmpty == false && organization.role == .seller
        } ?? organizations.first { organization in
            organization.party.isEmpty == false && organization.role == .mixed
        }

        guard let defaultSeller else { return }

        var party = defaultSeller.party
        if let account = defaultSeller.defaultBankAccount {
            party = account.apply(to: party)
        }

        draft.seller = party
        draft.updatedAt = Date()
        autosaveDraft()
    }

    static func defaultUnit(for type: DocumentType) -> String {
        switch type {
        case .invoice, .deliveryNote:
            return "шт"
        case .act:
            return "услуга"
        }
    }

    static func normalizeItems(in draft: inout DocumentDraft) {
        if draft.items.isEmpty {
            draft.items.append(DocumentItem(unit: defaultUnit(for: draft.type)))
        }

        guard draft.type == .act else { return }

        for index in draft.items.indices {
            draft.items[index].vatRate = nil
        }
    }

    static func merge(
        party: DocumentParty,
        role: Organization.Role,
        date: Date,
        into parties: inout [String: (
            party: DocumentParty,
            role: Organization.Role,
            count: Int,
            updatedAt: Date,
            bankAccounts: [OrganizationBankAccount],
            defaultBankAccountID: UUID?,
            isDefault: Bool
        )]
    ) {
        guard party.isEmpty == false else { return }

        let organization = Organization(party: party, role: role, updatedAt: date)
        if var existing = parties[organization.matchingKey] {
            existing.party = party
            existing.count += 1
            existing.updatedAt = max(existing.updatedAt, date)
            existing.role = existing.role == role ? role : .mixed
            if existing.bankAccounts.isEmpty {
                existing.bankAccounts = organization.normalizedBankAccounts
                existing.defaultBankAccountID = organization.defaultBankAccount?.id
            }
            parties[organization.matchingKey] = existing
        } else {
            parties[organization.matchingKey] = (
                party,
                role,
                1,
                date,
                organization.normalizedBankAccounts,
                organization.defaultBankAccount?.id,
                false
            )
        }
    }
}

// MARK: - Draft Persistence

private extension DocumentEditorViewModel {
    var autosaveKey: String {
        switch mode {
        case .create:
            return "billingflow.documentWizard.autosave.create.\(draft.type.rawValue)"
        case .duplicate:
            return "billingflow.documentWizard.autosave.duplicate.\(draft.sourceDocumentID?.uuidString ?? draft.id.uuidString)"
        case .edit(let document):
            return "billingflow.documentWizard.autosave.edit.\(document.id.uuidString)"
        }
    }

    func autosaveDraft() {
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
