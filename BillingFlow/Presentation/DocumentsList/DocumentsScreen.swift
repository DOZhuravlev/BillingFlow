import SwiftUI

struct DocumentsScreen: View {

    // MARK: - ViewModel

    @ObservedObject var viewModel: DocumentsListViewModel

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    quickActionsSection
                    documentsContentSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .scrollIndicators(.hidden)
        }
        .task {
            await viewModel.loadDocumentsIfNeeded()
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            quickActionButton(
                title: "Счет",
                systemImage: "doc.text",
                tint: .blue
            ) {
                viewModel.didTapCreateDocument(type: .invoice)
            }

            quickActionButton(
                title: "Акт",
                systemImage: "checkmark.seal",
                tint: .green
            ) {
                viewModel.didTapCreateDocument(type: .act)
            }

            quickActionButton(
                title: "Накладная",
                systemImage: "shippingbox",
                tint: .orange
            ) {
                viewModel.didTapCreateDocument(type: .deliveryNote)
            }
        }
    }

    // MARK: - Documents Content Section

    private var documentsContentSection: some View {
        Group {
            switch viewModel.state {
            case .idle:
                idleStateView

            case .loading:
                loadingStateView

            case .empty:
                emptyStateView

            case .error(let message):
                errorStateView(message: message)

            case .loaded(let documents):
                documentsList(documents)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - State Views

    private var idleStateView: some View {
        StatePlaceholderView(
            title: "Документы еще не загружены",
            message: "Нажмите повторить, чтобы получить список документов.",
            systemImage: "doc.text.magnifyingglass",
            buttonTitle: "Загрузить",
            action: {
                Task {
                    await viewModel.reload()
                }
            }
        )
    }

    private var loadingStateView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)

            Text("Загружаем документы...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 320)
    }

    private var emptyStateView: some View {
        StatePlaceholderView(
            title: "Документов пока нет",
            message: "Создайте первый документ через быстрые действия сверху.",
            systemImage: "tray",
            buttonTitle: "Обновить",
            action: {
                Task {
                    await viewModel.reload()
                }
            }
        )
    }

    private func errorStateView(message: String) -> some View {
        StatePlaceholderView(
            title: "Не удалось загрузить",
            message: message,
            systemImage: "wifi.exclamationmark",
            buttonTitle: "Повторить",
            action: {
                Task {
                    await viewModel.reload()
                }
            }
        )
    }

    // MARK: - Documents List

    private func documentsList(_ documents: [BusinessDocument]) -> some View {
        LazyVStack(spacing: 18) {
            ForEach(documents) { document in
                Button {
                    viewModel.didTapDocument(document: document)
                } label: {
                    DocumentCardView(document: document)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Reusable Actions

    private func quickActionButton(
        title: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(tint.opacity(0.14))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(tint.opacity(0.12), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Loaded") {
    NavigationStack {
        DocumentsScreen(
            viewModel: DocumentsListViewModel(
                router: PreviewDocumentsRouter(),
                documentsRepository: InMemoryDocumentsRepository()
            )
        )
    }
}

#Preview("Empty") {
    NavigationStack {
        DocumentsScreen(
            viewModel: DocumentsListViewModel(
                router: PreviewDocumentsRouter(),
                documentsRepository: InMemoryDocumentsRepository(documents: [])
            )
        )
    }
}

#Preview("Error") {
    NavigationStack {
        DocumentsScreen(
            viewModel: DocumentsListViewModel(
                router: PreviewDocumentsRouter(),
                documentsRepository: PreviewFailureDocumentsRepository()
            )
        )
    }
}

// MARK: - Preview Router

private final class PreviewDocumentsRouter: DocumentsRouterProtocol {
    func showCreateDocument(type: DocumentType) { }
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
