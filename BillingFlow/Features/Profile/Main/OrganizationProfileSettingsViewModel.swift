import Combine
import Foundation

@MainActor
final class OrganizationProfileSettingsViewModel: ObservableObject {

    enum PartyField {
        case displayName
        case fullName
        case taxID
        case registrationNumber
        case address
        case contactName
        case phone
        case email
    }

    enum BankField {
        case bankName
        case bankAccount
        case bankCode
        case correspondentAccount
    }

    struct Draft: Equatable {
        var id: UUID?
        var party: DocumentParty
        var bankAccounts: [OrganizationBankAccount]
        var defaultBankAccountID: UUID?
        var isDefault: Bool
        var createdAt: Date?

        static func empty(isDefault: Bool = false) -> Draft {
            Draft(
                id: nil,
                party: DocumentParty(),
                bankAccounts: [OrganizationBankAccount(isDefault: true)],
                defaultBankAccountID: nil,
                isDefault: isDefault,
                createdAt: nil
            )
        }
    }

    // MARK: - State

    @Published private(set) var organizations: [Organization] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var draft: Draft = .empty()
    @Published var searchQuery = ""
    @Published private(set) var searchResults: [OrganizationSuggestion] = []
    @Published private(set) var isSearching = false
    @Published private(set) var searchErrorMessage: String?
    @Published private(set) var isSearchVisible = false

    // MARK: - Dependencies

    private let organizationsRepository: OrganizationsRepositoryProtocol
    private let organizationSearchService: OrganizationSearchServiceProtocol
    private var searchTask: Task<Void, Never>?
    private var savedDraft: Draft = .empty()

    // MARK: - Initialization

    init(
        organizationsRepository: OrganizationsRepositoryProtocol,
        organizationSearchService: OrganizationSearchServiceProtocol
    ) {
        self.organizationsRepository = organizationsRepository
        self.organizationSearchService = organizationSearchService
    }

    deinit {
        searchTask?.cancel()
    }
}

// MARK: - Derived State

extension OrganizationProfileSettingsViewModel {
    var selectedOrganizationID: UUID? {
        draft.id
    }

    var isNewOrganization: Bool {
        draft.id == nil
    }

    var canSave: Bool {
        draft.party.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    var hasUnsavedChanges: Bool {
        draft != savedDraft
    }

    var title: String {
        isNewOrganization ? "Новая организация" : "Реквизиты организации"
    }

    var saveButtonTitle: String {
        isNewOrganization ? "Сохранить организацию" : "Сохранить изменения"
    }
}

// MARK: - Loading

extension OrganizationProfileSettingsViewModel {
    func load() async {
        guard isLoading == false else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let storedOrganizations = try await organizationsRepository.fetchOrganizations()
            organizations = storedOrganizations
                .filter { $0.role == .seller || $0.isDefault }
                .sorted { lhs, rhs in
                    if lhs.isDefault != rhs.isDefault {
                        return lhs.isDefault
                    }

                    return lhs.updatedAt > rhs.updatedAt
                }

            if let selectedID = draft.id,
               let selectedOrganization = organizations.first(where: { $0.id == selectedID }) {
                selectOrganization(selectedOrganization)
            } else if let defaultOrganization = organizations.first(where: \.isDefault) ?? organizations.first {
                selectOrganization(defaultOrganization)
            } else {
                draft = .empty(isDefault: true)
                savedDraft = draft
                resetSearch()
                isSearchVisible = false
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Editing

extension OrganizationProfileSettingsViewModel {
    func startNewOrganization() {
        draft = .empty(isDefault: organizations.isEmpty)
        savedDraft = draft
        resetSearch()
        isSearchVisible = true
    }

    func selectOrganization(_ organization: Organization) {
        let bankAccounts = organization.normalizedBankAccounts
        draft = Draft(
            id: organization.id,
            party: organization.party,
            bankAccounts: bankAccounts.isEmpty ? [OrganizationBankAccount(isDefault: true)] : bankAccounts,
            defaultBankAccountID: organization.defaultBankAccount?.id,
            isDefault: organization.isDefault,
            createdAt: organization.createdAt
        )
        savedDraft = draft
        resetSearch()
        isSearchVisible = false
    }

    func updatePartyField(_ field: PartyField, value: String) {
        switch field {
        case .displayName:
            draft.party.displayName = value
        case .fullName:
            draft.party.fullName = value
        case .taxID:
            draft.party.taxID = value
        case .registrationNumber:
            draft.party.registrationNumber = value
        case .address:
            draft.party.address = value
        case .contactName:
            draft.party.contactName = value
        case .phone:
            draft.party.phone = value
        case .email:
            draft.party.email = value
        }
    }

    func addBankAccount() {
        let account = OrganizationBankAccount(isDefault: draft.bankAccounts.isEmpty)
        draft.bankAccounts.append(account)
        draft.defaultBankAccountID = draft.defaultBankAccountID ?? account.id
    }

    func removeBankAccount(id: UUID) {
        guard draft.bankAccounts.count > 1 else { return }
        draft.bankAccounts.removeAll { $0.id == id }

        if draft.defaultBankAccountID == id {
            draft.defaultBankAccountID = draft.bankAccounts.first?.id
        }

        normalizeDefaultBankAccount()
    }

    func setDefaultBankAccount(id: UUID) {
        draft.defaultBankAccountID = id
        normalizeDefaultBankAccount()
    }

    func updateBankAccount(id: UUID, field: BankField, value: String) {
        guard let index = draft.bankAccounts.firstIndex(where: { $0.id == id }) else { return }

        switch field {
        case .bankName:
            draft.bankAccounts[index].bankName = value
        case .bankAccount:
            draft.bankAccounts[index].bankAccount = value
        case .bankCode:
            draft.bankAccounts[index].bankCode = value
        case .correspondentAccount:
            draft.bankAccounts[index].correspondentAccount = value
        }
    }

    func setDefaultOrganization(_ isDefault: Bool) {
        draft.isDefault = isDefault
    }

    func makeCurrentOrganizationDefault() {
        draft.isDefault = true
    }
}

// MARK: - Saving

extension OrganizationProfileSettingsViewModel {
    func save() async {
        guard canSave else {
            errorMessage = "Укажите название организации"
            return
        }

        do {
            let organization = makeOrganization()
            try await organizationsRepository.save(organization: organization)

            if organization.isDefault {
                try await clearDefaultFlag(except: organization.id)
            }

            await load()
            selectOrganization(organization)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteSelectedOrganization() async {
        guard let id = draft.id else { return }

        do {
            try await organizationsRepository.deleteOrganization(id: id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Search

extension OrganizationProfileSettingsViewModel {
    func updateSearchQuery(_ query: String) {
        searchQuery = query
        searchTask?.cancel()

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= 2 else {
            searchResults = []
            searchErrorMessage = nil
            isSearching = false
            return
        }

        isSearching = true
        searchErrorMessage = nil

        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard Task.isCancelled == false else { return }

            await self?.performSearch(query: trimmedQuery)
        }
    }

    func selectSuggestion(_ suggestion: OrganizationSuggestion) {
        draft.party = suggestion.party
        resetSearch()
        isSearchVisible = false
    }

    func resetSearch() {
        searchTask?.cancel()
        searchQuery = ""
        searchResults = []
        searchErrorMessage = nil
        isSearching = false
    }
}

// MARK: - Private Helpers

private extension OrganizationProfileSettingsViewModel {
    func performSearch(query: String) async {
        do {
            let results = try await organizationSearchService.searchOrganizations(query: query)
            guard Task.isCancelled == false else { return }
            searchResults = results
            searchErrorMessage = results.isEmpty ? "Ничего не нашли" : nil
            isSearching = false
        } catch is CancellationError {
            isSearching = false
        } catch {
            searchResults = []
            searchErrorMessage = error.localizedDescription
            isSearching = false
        }
    }

    func makeOrganization() -> Organization {
        normalizeDefaultBankAccount()
        let accounts = draft.bankAccounts.filter { $0.isEmpty == false }
        let defaultAccountID = draft.defaultBankAccountID ?? accounts.first?.id

        return Organization(
            id: draft.id ?? UUID(),
            party: draft.party,
            role: .seller,
            bankAccounts: accounts,
            defaultBankAccountID: defaultAccountID,
            isDefault: draft.isDefault || organizations.isEmpty,
            createdAt: draft.createdAt ?? Date(),
            updatedAt: Date()
        )
    }

    func normalizeDefaultBankAccount() {
        let defaultID = draft.defaultBankAccountID ?? draft.bankAccounts.first?.id
        draft.defaultBankAccountID = defaultID

        for index in draft.bankAccounts.indices {
            draft.bankAccounts[index].isDefault = draft.bankAccounts[index].id == defaultID
        }
    }

    func clearDefaultFlag(except id: UUID) async throws {
        let storedOrganizations = try await organizationsRepository.fetchOrganizations()

        for var organization in storedOrganizations where organization.id != id && organization.isDefault {
            organization.isDefault = false
            organization.updatedAt = Date()
            try await organizationsRepository.save(organization: organization)
        }
    }
}
