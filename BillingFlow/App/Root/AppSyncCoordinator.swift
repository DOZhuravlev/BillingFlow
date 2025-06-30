import Combine
import Network
import UIKit

@MainActor
final class AppSyncCoordinator {
    private let organizationsRepository: SyncingOrganizationsRepository
    private let documentsRepository: SyncingDocumentsRepository
    private let dealsRepository: SyncingDealsRepository
    private let documentEventsStore: DocumentEventsStore
    private let dealEventsStore: DealEventsStore
    private let organizationEventsStore: OrganizationEventsStore

    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "com.my.BillingFlow.network-monitor")
    private var cancellables = Set<AnyCancellable>()
    private var syncTask: Task<Void, Never>?
    private var isStarted = false
    private var isNetworkAvailable = true

    init(
        organizationsRepository: SyncingOrganizationsRepository,
        documentsRepository: SyncingDocumentsRepository,
        dealsRepository: SyncingDealsRepository,
        documentEventsStore: DocumentEventsStore,
        dealEventsStore: DealEventsStore,
        organizationEventsStore: OrganizationEventsStore
    ) {
        self.organizationsRepository = organizationsRepository
        self.documentsRepository = documentsRepository
        self.dealsRepository = dealsRepository
        self.documentEventsStore = documentEventsStore
        self.dealEventsStore = dealEventsStore
        self.organizationEventsStore = organizationEventsStore
    }

    func start() {
        guard isStarted == false else { return }
        isStarted = true

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.scheduleSynchronization()
            }
            .store(in: &cancellables)

        networkMonitor.pathUpdateHandler = { [self] path in
            Task { @MainActor [self] in
                let wasAvailable = self.isNetworkAvailable
                self.isNetworkAvailable = path.status == .satisfied
                if self.isNetworkAvailable && wasAvailable == false {
                    self.scheduleSynchronization(immediate: true)
                }
            }
        }
        networkMonitor.start(queue: networkQueue)
        scheduleSynchronization(immediate: true)
    }

    func accountDidChange() {
        documentEventsStore.sendDocumentsDidChange()
        dealEventsStore.sendDealsDidChange()
        organizationEventsStore.sendOrganizationsDidChange()
        scheduleSynchronization(immediate: true)
    }
}

private extension AppSyncCoordinator {
    func scheduleSynchronization(immediate: Bool = false) {
        syncTask?.cancel()
        syncTask = Task { [weak self] in
            guard let self else { return }
            let delays: [UInt64] = immediate
                ? [0, 2_000_000_000, 10_000_000_000]
                : [500_000_000, 2_000_000_000, 10_000_000_000]

            for delay in delays {
                guard Task.isCancelled == false else { return }
                if delay > 0 {
                    try? await Task.sleep(nanoseconds: delay)
                }
                guard Task.isCancelled == false else { return }
                guard self.isNetworkAvailable else { return }

                async let organizationsSucceeded = self.organizationsRepository.synchronizeReportingResult()
                async let documentsSucceeded = self.documentsRepository.synchronizeReportingResult()
                async let dealsSucceeded = self.dealsRepository.synchronizeReportingResult()
                let results = await (organizationsSucceeded, documentsSucceeded, dealsSucceeded)
                if results.0 && results.1 && results.2 {
                    return
                }
            }
        }
    }
}
