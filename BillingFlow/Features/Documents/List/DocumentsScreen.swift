import SwiftUI

struct DocumentsScreen: View {

    // MARK: - Dependencies

    @ObservedObject var viewModel: DocumentsListViewModel

    // MARK: - State

    @State private var isFilterSheetPresented = false
    @State private var isCounterpartyPickerPresented = false

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppSpacing.lg) {
                    headerView
                    activeFiltersSection
                    documentsContentSection
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppLayout.floatingTabBarBottomInset)
            }
            .scrollIndicators(.hidden)
        }
        .sheet(isPresented: $isFilterSheetPresented) {
            filterSheet
        }
        .sheet(isPresented: $isCounterpartyPickerPresented) {
            counterpartyPickerSheet
        }
        .task {
            await viewModel.loadDocumentsIfNeeded()
        }
    }
}

// MARK: - Layout

private extension DocumentsScreen {

    var backgroundLayer: some View {
        AppColor.Brand.background
            .ignoresSafeArea()
    }

    var documentsContentSection: some View {
        Group {
            switch viewModel.state {
            case .idle:
                EmptyView()

            case .loading:
                loadingView

            case .empty:
                emptyDocumentsView

            case .error(let message):
                errorView(message)

            case .loaded:
                loadedDocumentsView
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Header & Filters

private extension DocumentsScreen {

    var headerView: some View {
        DocumentsHeaderView(
            counterpartyTitle: viewModel.selectedCounterpartyTitle,
            hasActiveFilters: viewModel.hasAdvancedFilters,
            onCounterpartyTap: {
                isCounterpartyPickerPresented = true
            },
            onSearchTap: {
                // search later
            },
            onFilterTap: {
                isFilterSheetPresented = true
            }
        )
    }

    @ViewBuilder
    var activeFiltersSection: some View {
        if viewModel.hasAdvancedFilters {
            DocumentsActiveFilterChipsView(
                chips: viewModel.activeFilterChips,
                onRemove: { chip in
                    withAnimation(.easeInOut(duration: 0.18)) {
                        viewModel.removeFilterChip(chip)
                    }
                },
                onReset: {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        viewModel.resetAdvancedFilters()
                    }
                }
            )
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - Documents List

private extension DocumentsScreen {

    @ViewBuilder
    var loadedDocumentsView: some View {
        if viewModel.documentSections.isEmpty {
            if viewModel.hasActiveFilters {
                filteredEmptyView
            } else {
                emptyDocumentsView
            }
        } else {
            groupedDocumentsList
        }
    }

    var groupedDocumentsList: some View {
        LazyVStack(alignment: .leading, spacing: AppSpacing.lg) {
            ForEach(viewModel.documentSections) { section in
                DocumentsMonthSectionView(
                    section: section,
                    onDocumentTap: { document in
                        viewModel.didTapDocument(document: document)
                    }
                )
            }
        }
    }
}

// MARK: - Sheets

private extension DocumentsScreen {

    var filterSheet: some View {
        DocumentsFilterSheetView(filter: filterBinding)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
    }

    var counterpartyPickerSheet: some View {
        DocumentsCounterpartyPickerSheetView(
            counterparties: viewModel.availableCounterparties,
            selectedCounterpartyName: viewModel.filter.counterpartyName,
            onSelect: { counterparty in
                withAnimation(.easeInOut(duration: 0.18)) {
                    viewModel.selectCounterparty(counterparty)
                }

                isCounterpartyPickerPresented = false
            }
        )
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Bindings

private extension DocumentsScreen {

    var filterBinding: Binding<DocumentsFilter> {
        Binding(
            get: {
                viewModel.filter
            },
            set: { filter in
                viewModel.applyFilter(filter)
            }
        )
    }
}

// MARK: - States

private extension DocumentsScreen {

    var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(.white)

            Text("Загружаем документы")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.78))
        }
        .frame(maxWidth: .infinity, minHeight: 260)
    }

    var emptyDocumentsView: some View {
        DocumentsStatePlaceholderView(
            title: "Документов пока нет",
            message: "Создайте первый счёт, акт или счёт-фактуру.",
            systemImage: "doc.badge.plus",
            buttonTitle: "Создать счёт",
            action: {
                viewModel.didTapCreateDocument(type: .invoice)
            }
        )
    }

    var filteredEmptyView: some View {
        DocumentsStatePlaceholderView(
            title: "Ничего не найдено",
            message: "Попробуйте изменить или сбросить фильтры.",
            systemImage: "line.3.horizontal.decrease.circle",
            buttonTitle: "Сбросить фильтры",
            action: {
                withAnimation(.easeInOut(duration: 0.18)) {
                    viewModel.resetAllFilters()
                }
            }
        )
    }

    func errorView(_ message: String) -> some View {
        DocumentsStatePlaceholderView(
            title: "Не удалось загрузить документы",
            message: message,
            systemImage: "exclamationmark.triangle",
            buttonTitle: "Повторить",
            action: {
                Task {
                    await viewModel.reload()
                }
            }
        )
    }
}

// MARK: - Preview

#Preview("Loaded") {
    NavigationStack {
        DocumentsScreen(
            viewModel: DocumentsListViewModel(
                coordinator: PreviewDocumentsRouter(),
                documentsRepository: InMemoryDocumentsRepository()
            )
        )
    }
}

#Preview("Empty") {
    NavigationStack {
        DocumentsScreen(
            viewModel: DocumentsListViewModel(
                coordinator: PreviewDocumentsRouter(),
                documentsRepository: InMemoryDocumentsRepository(documents: [])
            )
        )
    }
}

#Preview("Error") {
    NavigationStack {
        DocumentsScreen(
            viewModel: DocumentsListViewModel(
                coordinator: PreviewDocumentsRouter(),
                documentsRepository: PreviewFailureDocumentsRepository()
            )
        )
    }
}

// MARK: - Preview

private final class PreviewDocumentsRouter: DocumentsCoordinatorProtocol {
    func start() { }
    func showDetail(document: BusinessDocument) { }
    func showCreateDocument(type: DocumentType) { }
    func showDuplicateDocument(document: BusinessDocument) { }
    func showEditDocument(document: BusinessDocument) { }
    func showPreview(document: BusinessDocument) { }
    func finishDocumentFlowAfterShare() { }
    func dismiss() { }
    func pop() { }
}

// MARK: - Preview Error Repository

private struct PreviewFailureDocumentsRepository: DocumentsRepositoryProtocol {

    struct PreviewError: LocalizedError {
        var errorDescription: String? {
            "Не удалось подключиться к хранилищу документов."
        }
    }

    func fetchDocuments() async throws -> [BusinessDocument] {
        throw PreviewError()
    }

    func fetchDocument(id: UUID) async throws -> BusinessDocument? {
        nil
    }

    func save(document: BusinessDocument) async throws { }

    func deleteDocument(id: UUID) async throws { }
}
