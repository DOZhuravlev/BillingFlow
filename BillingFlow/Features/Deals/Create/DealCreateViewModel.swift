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
    @Published private(set) var isSaving = false
    @Published private(set) var errorMessage: String?

    private weak var coordinator: DealsCoordinatorProtocol?
    private let dealsRepository: DealsRepositoryProtocol
    private let organizationsRepository: OrganizationsRepositoryProtocol
    private let dealEventsStore: DealEventsStore

    init(
        type: DealType,
        coordinator: DealsCoordinatorProtocol,
        dealsRepository: DealsRepositoryProtocol,
        organizationsRepository: OrganizationsRepositoryProtocol,
        dealEventsStore: DealEventsStore
    ) {
        self.type = type
        self.coordinator = coordinator
        self.dealsRepository = dealsRepository
        self.organizationsRepository = organizationsRepository
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
}
