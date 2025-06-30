import Combine
import Foundation

@MainActor
final class DealCreateViewModel: ObservableObject {
    enum Step: Int, CaseIterable { case type, counterparty, details }

    @Published var step: Step = .type
    @Published var type: DealType
    @Published var counterparty: DocumentParty = DocumentParty()
    @Published var title = ""
    @Published var amountText = ""
    @Published var dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @Published private(set) var counterparties: [Organization] = []
    @Published private(set) var organizationSearchResults: [OrganizationSuggestion] = []
    @Published private(set) var isSearchingOrganizations = false
    @Published private(set) var organizationSearchErrorMessage: String?
    @Published var organizationSearchQuery = ""
    @Published private(set) var isSaving = false
    @Published private(set) var errorMessage: String?

    private weak var coordinator: DealsCoordinatorProtocol?
    private let dealsRepository: DealsRepositoryProtocol
    private let organizationsRepository: OrganizationsRepositoryProtocol
    private let organizationSearchService: OrganizationSearchServiceProtocol
    private let dealEventsStore: DealEventsStore
    private var organizationSearchTask: Task<Void, Never>?

    init(
        type: DealType,
        coordinator: DealsCoordinatorProtocol,
        dealsRepository: DealsRepositoryProtocol,
        organizationsRepository: OrganizationsRepositoryProtocol,
        organizationSearchService: OrganizationSearchServiceProtocol,
        dealEventsStore: DealEventsStore
    ) {
        self.type = type
        self.coordinator = coordinator
        self.dealsRepository = dealsRepository
        self.organizationsRepository = organizationsRepository
        self.organizationSearchService = organizationSearchService
        self.dealEventsStore = dealEventsStore
    }

    var amount: Decimal {
        Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var canContinue: Bool {
        switch step {
        case .type: return true
        case .counterparty: return counterparty.isEmpty == false
        case .details: return title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false && amount > 0
        }
    }

    func load() async {
        do {
            counterparties = try await organizationsRepository.fetchOrganizations()
                .filter { $0.role != .seller && $0.party.isEmpty == false }
                .sorted { $0.updatedAt > $1.updatedAt }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectCounterparty(_ organization: Organization) {
        counterparty = organization.party
        resetOrganizationSearch()
    }

    func selectCounterparty(_ suggestion: OrganizationSuggestion) {
        counterparty = suggestion.party
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
                await self?.finishCancelledSearch()
            }
        }
    }

    func resetOrganizationSearch() {
        organizationSearchTask?.cancel()
        organizationSearchTask = nil
        organizationSearchQuery = ""
        organizationSearchResults = []
        organizationSearchErrorMessage = nil
        isSearchingOrganizations = false
    }

    func next() async {
        guard canContinue else { return }
        if let next = Step(rawValue: step.rawValue + 1) {
            step = next
        } else {
            await save()
        }
    }

    func back() {
        guard let previous = Step(rawValue: step.rawValue - 1) else {
            coordinator?.pop()
            return
        }
        step = previous
    }

    private func save() async {
        guard isSaving == false else { return }
        isSaving = true
        defer { isSaving = false }

        let deal = Deal(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            type: type,
            counterparty: counterparty,
            amount: amount,
            dueDate: dueDate,
            phone: counterparty.phone
        )

        do {
            try await dealsRepository.save(deal: deal)
            dealEventsStore.sendDealsDidChange()
            coordinator?.finishDealCreation(deal)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func performOrganizationSearch(query: String) async {
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

    private func finishCancelledSearch() {
        if organizationSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 {
            isSearchingOrganizations = false
        }
    }
}
