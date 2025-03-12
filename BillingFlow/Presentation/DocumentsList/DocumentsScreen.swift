import SwiftUI

struct DocumentsScreen: View {

    // MARK: - Properties

    @StateObject private var viewModel: DocumentsListViewModel

    // MARK: - Initialization

    init(repository: DocumentsRepositoryProtocol) {
        _viewModel = StateObject(
            wrappedValue: DocumentsListViewModel(repository: repository)
        )
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    headerActions
                    contentView
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .scrollIndicators(.hidden)
        }
        .task {
            await viewModel.loadDocuments()
        }
    }

    // MARK: - Components

    private var backgroundColor: Color {
        Color(.systemGroupedBackground)
    }

    private var headerActions: some View {
        HStack(spacing: 12) {
            quickActionButton(title: "Счет", systemImage: "doc.text", tint: .blue)
            quickActionButton(title: "Акт", systemImage: "checkmark.seal", tint: .green)
            quickActionButton(title: "Накладная", systemImage: "shippingbox", tint: .orange)
        }
    }

    private func quickActionButton(
        title: String,
        systemImage: String,
        tint: Color
    ) -> some View {
        Button(action: {}) {
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

    private var contentView: some View {
        Group {
            switch viewModel.state {
            case .idle:
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

            case .loading:
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.large)

                    Text("Загружаем документы...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 320)

            case .empty:
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

            case .error(let message):
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

            case .loaded(let documents):
                LazyVStack(spacing: 18) {
                    ForEach(documents) { document in
                        DocumentCardView(document: document)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
