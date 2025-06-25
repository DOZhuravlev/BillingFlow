import Combine
import Foundation

@MainActor
final class DealDetailViewModel: ObservableObject {
    struct DocumentSlot: Identifiable {
        let kind: DealDocumentKind
        let documents: [BusinessDocument]
        var id: DealDocumentKind { kind }
        var latestDocument: BusinessDocument? { documents.sorted { $0.date > $1.date }.first }
    }

    @Published private(set) var deal: Deal
    @Published private(set) var documents: [BusinessDocument] = []
    @Published var note: String
    @Published var phone: String
    @Published var reminderDate: Date
    @Published var isReminderEnabled: Bool
    @Published private(set) var errorMessage: String?

    private weak var coordinator: DealsCoordinatorProtocol?
    private let dealsRepository: DealsRepositoryProtocol
    private let documentsRepository: DocumentsRepositoryProtocol
    private let dealEventsStore: DealEventsStore
    private var cancellables = Set<AnyCancellable>()

    init(
        deal: Deal,
        coordinator: DealsCoordinatorProtocol,
        dealsRepository: DealsRepositoryProtocol,
        documentsRepository: DocumentsRepositoryProtocol,
        dealEventsStore: DealEventsStore,
        documentEventsStore: DocumentEventsStore
    ) {
        self.deal = deal
        self.coordinator = coordinator
        self.dealsRepository = dealsRepository
        self.documentsRepository = documentsRepository
        self.dealEventsStore = dealEventsStore
        self.note = deal.note
        self.phone = deal.phone
        self.reminderDate = deal.reminderDate ?? Date()
        self.isReminderEnabled = deal.reminderDate != nil

        documentEventsStore.documentsDidChangePublisher
            .sink { [weak self] in Task { await self?.reload() } }
            .store(in: &cancellables)
    }

    var status: DealStatus { deal.effectiveStatus(documents: documents) }
    var progress: Double { status.progress }
    var documentSlots: [DocumentSlot] {
        DealDocumentKind.allCases.map { kind in
            DocumentSlot(
                kind: kind,
                documents: documents.filter { DealDocumentKind.kind(for: $0.type) == kind }
            )
        }
    }
    var invoiceTotal: Decimal { documents.filter { $0.type == .invoice && $0.status != .draft }.reduce(0) { $0 + $1.totals.total } }
    var paidTotal: Decimal { documents.filter { $0.type == .invoice && $0.paidAt != nil }.reduce(0) { $0 + $1.totals.total } }
    var hasUnsavedChanges: Bool {
        note != deal.note || phone != deal.phone || (isReminderEnabled ? reminderDate : nil) != deal.reminderDate
    }

    func reload() async {
        do {
            if let updatedDeal = try await dealsRepository.fetchDeal(id: deal.id) { deal = updatedDeal }
            documents = try await documentsRepository.fetchDocuments().filter { $0.dealID == deal.id }
        } catch { errorMessage = error.localizedDescription }
    }

    func pop() { coordinator?.pop() }

    func selectStatus(_ status: DealStatus) {
        deal.statusOverride = status
        deal.updatedAt = Date()
        Task { await persistDeal() }
    }

    func useAutomaticStatus() {
        deal.statusOverride = nil
        deal.updatedAt = Date()
        Task { await persistDeal() }
    }

    func didTapSlot(_ slot: DocumentSlot) {
        if let document = slot.latestDocument {
            coordinator?.showDocument(document)
        } else if let type = slot.kind.supportedDocumentType {
            coordinator?.createDocument(type: type, for: deal)
        }
    }

    func saveDetails() async {
        deal.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        deal.phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        deal.reminderDate = isReminderEnabled ? reminderDate : nil
        deal.updatedAt = Date()
        await persistDeal()
    }

    private func persistDeal() async {
        do {
            try await dealsRepository.save(deal: deal)
            dealEventsStore.sendDealsDidChange()
        } catch { errorMessage = error.localizedDescription }
    }
}
