import SwiftUI

enum AppLayout {
    static let floatingTabBarHeight: CGFloat = 58
    static let floatingTabBarBottomOffset: CGFloat = 20
    static let floatingTabBarContentSpacing: CGFloat = 24

    static var floatingTabBarBottomInset: CGFloat {
        floatingTabBarHeight + floatingTabBarBottomOffset + floatingTabBarContentSpacing
    }
}

struct HomeScreen: View {

    @ObservedObject var viewModel: HomeViewModel

    @State private var scrollOffset: CGFloat = .zero

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundLayer
            ScrollView {
                ScrollOffsetObserver { offset in
                    scrollOffset = max(offset.y, 0)
                }
                .frame(width: 0, height: 0)

                VStack(spacing: AppSpacing.lg) {
                    headerView
                    dashboardContentSection
                }
                .padding(.bottom, AppLayout.floatingTabBarBottomInset)
            }
            .scrollIndicators(.hidden)
            .overlay(alignment: .top) {
                topBlurOverlay
                    .opacity(topBlurOpacity)
                    .animation(.easeInOut(duration: 0.28), value: topBlurOpacity)
            }
        }
        .task {
            await viewModel.loadDocumentsIfNeeded()
        }
    }
}

// MARK: - Layout

private extension HomeScreen {

    var backgroundLayer: some View {
        AppColor.Brand.background
            .ignoresSafeArea()
    }

    var dashboardContentSection: some View {
        Group {
            switch viewModel.state {
            case .idle:
                idleStateView

            case .loading:
                loadingStateView

            case .loaded:
                loadedDashboardView

            case .empty:
                emptyStateView

            case .error(let message):
                errorStateView(message: message)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Header

private extension HomeScreen {

    var headerView: some View {
        HStack(spacing: 10) {
            Image("logo")
                .resizable()
                .frame(width: 50, height: 50)

            Text("Счет онлайн")
                .font(.system(size: 22))
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Spacer()

            notificationButton
        }
        .frame(height: 50)
        .padding(.horizontal)
    }

    var notificationButton: some View {
        Button {

        } label: {
            Image(systemName: "bell.fill")
                .frame(width: 40, height: 40)
                .foregroundStyle(.white)
                .background {
                    Circle()
                        .fill(.white.opacity(0.15))
                        .blur(radius: 1)
                }
                .overlay {
                    Circle()
                        .stroke(.white, lineWidth: 1)
                }
                .clipShape(Circle())
        }
    }

}

// MARK: - Dashboard

private extension HomeScreen {

    var loadedDashboardView: some View {
        VStack(spacing: AppSpacing.lg) {
            quickActionsSection
            recentDocumentsSection
            topOrganizationsSection
        }
    }

    var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader("Быстро создать", showsAll: false)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    quickActionButton(
                        metric: FinanceMetric(
                            title: "Создать счёт",
                            amount: "Счёт",
                            style: .income
                        )
                    ) {
                        viewModel.didTapCreateDocument(type: .invoice)
                    }

                    quickActionButton(
                        metric: FinanceMetric(
                            title: "Создать акт",
                            amount: "Акт",
                            style: .pending
                        )
                    ) {
                        viewModel.didTapCreateDocument(type: .act)
                    }

                    quickActionButton(
                        metric: FinanceMetric(
                            title: "Счёт-фактура",
                            amount: "Фактура",
                            style: .debt
                        )
                    ) {
                        viewModel.didTapCreateDocument(type: .deliveryNote)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
        }
    }

    var recentDocumentsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader("Документы")

            VStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.recentDocuments) { document in
                    BillGroupCard(
                        iconName: document.iconName,
                        title: document.title,
                        date: document.subtitle,
                        amount: document.amount,
                        statusTitle: document.statusTitle,
                        statusAmount: document.statusAmount,
                        statusStyle: document.statusStyle
                    )
                    .onTapGesture {
                        viewModel.didTapDocument(id: document.id)
                    }
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }

    var topOrganizationsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader("Частые контрагенты")

            VStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.topOrganizations) { organization in
                    organizationRow(organization)
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                        .stroke(.white.opacity(0.35), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.14), radius: 24, x: 0, y: 12)
        }
    }
}

// MARK: - States

private extension HomeScreen {

    var idleStateView: some View {
        Color.clear
            .frame(height: 1)
    }

    var loadingStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            quickActionsSkeleton
            sectionSkeleton(title: "Недавние документы")
            sectionSkeleton(title: "Частые контрагенты")
        }
        .padding(.horizontal, AppSpacing.md)
    }

    var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            MaterialCard {
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))

                    Text("Документов пока нет")
                        .font(AppFont.Text.headline)
                        .foregroundStyle(.white)

                    Text("Создайте первый счёт, акт или счёт-фактуру — после этого здесь появится сводка.")
                        .font(AppFont.Text.caption)
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)

                    Button {
                        viewModel.didTapCreateDocument(type: .invoice)
                    } label: {
                        Text("Создать счёт")
                            .font(AppFont.Control.button)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundStyle(.black)
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }

    func errorStateView(message: String) -> some View {
        MaterialCard {
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.yellow)

                Text("Не удалось загрузить данные")
                    .font(AppFont.Text.headline)
                    .foregroundStyle(.white)

                Text(message)
                    .font(AppFont.Text.caption)
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)

                Button {
                    Task {
                        await viewModel.reload()
                    }
                } label: {
                    Text("Повторить")
                        .font(AppFont.Control.button)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }
}

// MARK: - Loading Skeleton

private extension HomeScreen {

    var quickActionsSkeleton: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader("Быстро создать", showsAll: false)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(0..<3, id: \.self) { _ in
                        skeletonMetricCard
                            .frame(width: 148)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
        }
    }

    func sectionSkeleton(title: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(title)

            VStack(spacing: AppSpacing.sm) {
                skeletonRow
                skeletonRow
                skeletonRow
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }

    var skeletonMetricCard: some View {
        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
            .fill(.white.opacity(0.18))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            }
            .frame(maxWidth: .infinity, minHeight: 110)
    }

    var skeletonRow: some View {
        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
            .fill(.white.opacity(0.16))
            .frame(height: 54)
            .overlay(alignment: .leading) {
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(.white.opacity(0.22))
                        .frame(width: 140, height: 10)

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(.white.opacity(0.14))
                        .frame(width: 92, height: 8)
                }
                .padding(.horizontal, AppSpacing.md)
            }
    }
}

// MARK: - Overlay

private extension HomeScreen {

    var topBlurOverlay: some View {
        VStack(spacing: 0) {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.14),
                        Color.black.opacity(0.06),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(height: 90)
            .mask {
                LinearGradient(
                    colors: [
                        .black,
                        .black.opacity(0.85),
                        .black.opacity(0.35),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }

            Spacer()
        }
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
    }

    var topBlurOpacity: CGFloat {
        let threshold: CGFloat = 2
        let distance: CGFloat = 2
        let progress = max((scrollOffset - threshold) / distance, 0)
        return min(progress, 1)
    }
}

// MARK: - Components

private extension HomeScreen {

    func sectionHeader(_ title: String, showsAll: Bool = true) -> some View {
        HStack {
            Text(title)
                .font(AppFont.Text.headline)
                .foregroundStyle(.white)

            Spacer()

            if showsAll {
                Text("Все")
                    .font(AppFont.Text.headline)
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal)
    }

    func quickActionButton(
        metric: FinanceMetric,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            BalanceSummaryCard(metric: metric)
                .frame(width: 148)
                .opacity(isEnabled ? 1 : 0.48)
        }
        .buttonStyle(.plain)
        .disabled(isEnabled == false)
    }

    func organizationRow(_ organization: TopOrganizationMetric) -> some View {
        Button {

        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "briefcase.fill")

                VStack(alignment: .leading, spacing: 4) {
                    Text(organization.name)
                        .font(AppFont.Text.caption)
                        .foregroundStyle(AppColor.Text.primary)

                    Text("Документов - \(organization.documentCount)")
                        .font(AppFont.Text.caption)
                        .foregroundStyle(AppColor.Text.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppColor.Text.secondary)
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.sm)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(.white.opacity(0.38))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .stroke(.white.opacity(0.28), lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Loaded") {
    NavigationStack {
        HomeScreen(
            viewModel: HomeViewModel(
                coordinator: PreviewDocumentsRouter(),
                documentsRepository: PreviewDocumentsRepository.loaded,
                organizationsRepository: PreviewOrganizationsRepository.loaded
            )
        )
    }
}

#Preview("Loading") {
    NavigationStack {
        HomeScreen(
            viewModel: HomeViewModel(
                coordinator: PreviewDocumentsRouter(),
                documentsRepository: PreviewDocumentsRepository.loading,
                organizationsRepository: PreviewOrganizationsRepository.loaded
            )
        )
    }
}

#Preview("Empty") {
    NavigationStack {
        HomeScreen(
            viewModel: HomeViewModel(
                coordinator: PreviewDocumentsRouter(),
                documentsRepository: PreviewDocumentsRepository.empty,
                organizationsRepository: PreviewOrganizationsRepository.empty
            )
        )
    }
}

#Preview("Error") {
    NavigationStack {
        HomeScreen(
            viewModel: HomeViewModel(
                coordinator: PreviewDocumentsRouter(),
                documentsRepository: PreviewDocumentsRepository.failure,
                organizationsRepository: PreviewOrganizationsRepository.loaded
            )
        )
    }
}

// MARK: - Preview Router

private final class PreviewDocumentsRouter: HomeCoordinatorProtocol {
    func showNotifications() {

    }

    func showProfile() {

    }

    func showDocument(_ document: BusinessDocument) {

    }

    func showDocumentPreview(_ document: BusinessDocument) {

    }

    func showAllDocuments() {

    }

    func showOrganization(_ organization: UUID) {

    }

    func showAllOrganizations() {

    }

    func showFinanceDetails(filter: HomeFinanceFilter) {

    }

    func start() { }
    func showCreateDocument(type: DocumentType) { }
    func showDuplicateDocument(_ document: BusinessDocument) { }
    func showEditDocument(document: BusinessDocument) { }
    func showPreview(document: BusinessDocument) { }
    func finishDocumentFlowAfterShare() { }
    func dismiss() { }
    func pop() { }
}

// MARK: - Preview Error Repository

private struct PreviewDocumentsRepository: DocumentsRepositoryProtocol {

    enum Scenario {
        case loaded
        case loading
        case empty
        case failure
    }

    static let loaded = PreviewDocumentsRepository(scenario: .loaded)
    static let loading = PreviewDocumentsRepository(scenario: .loading)
    static let empty = PreviewDocumentsRepository(scenario: .empty)
    static let failure = PreviewDocumentsRepository(scenario: .failure)

    let scenario: Scenario

    func fetchDocuments() async throws -> [BusinessDocument] {
        switch scenario {
        case .loaded:
            return Self.sampleDocuments

        case .loading:
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            return Self.sampleDocuments

        case .empty:
            return []

        case .failure:
            throw PreviewError()
        }
    }

    func fetchDocument(id: UUID) async throws -> BusinessDocument? {
        try await fetchDocuments().first { $0.id == id }
    }

    func save(document: BusinessDocument) async throws { }

    func deleteDocument(id: UUID) async throws { }
}

private extension PreviewDocumentsRepository {

    struct PreviewError: LocalizedError {
        var errorDescription: String? {
            "Не удалось подключиться к хранилищу документов."
        }
    }

    static let sampleDocuments: [BusinessDocument] = [
        BusinessDocument(
            type: .invoice,
            number: "INV-001",
            date: Date(),
            seller: DocumentParty(displayName: "ООО BillingFlow Studio"),
            buyer: DocumentParty(
                displayName: "ООО Альфа",
                taxID: "7701234567"
            ),
            items: [
                DocumentItem(
                    title: "Разработка интерфейса",
                    quantity: 1,
                    unit: "услуга",
                    price: 45_000
                )
            ],
            notes: "",
            currencyCode: "RUB",
            status: .ready
        ),
        BusinessDocument(
            type: .invoice,
            number: "INV-002",
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            seller: DocumentParty(displayName: "ООО BillingFlow Studio"),
            buyer: DocumentParty(
                displayName: "ООО Вектор",
                taxID: "6678123456"
            ),
            items: [
                DocumentItem(
                    title: "Подготовка PDF-документа",
                    quantity: 2,
                    unit: "час",
                    price: 3_500
                )
            ],
            notes: "",
            currencyCode: "RUB",
            status: .shared
        )
    ]
}

private struct PreviewOrganizationsRepository: OrganizationsRepositoryProtocol {

    static let loaded = PreviewOrganizationsRepository(organizations: [
        Organization(
            party: DocumentParty(
                displayName: "ООО Альфа",
                taxID: "7701234567"
            ),
            role: .buyer
        ),
        Organization(
            party: DocumentParty(
                displayName: "ООО Вектор",
                taxID: "6678123456"
            ),
            role: .buyer
        )
    ])
    static let empty = PreviewOrganizationsRepository(organizations: [])

    let organizations: [Organization]

    func fetchOrganizations() async throws -> [Organization] {
        organizations
    }

    func save(organization: Organization) async throws { }

    func upsert(party: DocumentParty, role: Organization.Role) async throws { }
}
