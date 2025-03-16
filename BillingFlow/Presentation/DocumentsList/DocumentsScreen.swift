import SwiftUI

struct DocumentsScreen: View {

    // MARK: - Properties

    private let repository: DocumentsRepositoryProtocol
    @StateObject private var viewModel: DocumentsListViewModel
    @State private var activeEditor: ActiveEditor?

    // MARK: - Initialization

    init(repository: DocumentsRepositoryProtocol) {
        self.repository = repository
        _viewModel = StateObject(
            wrappedValue: DocumentsListViewModel(repository: repository)
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
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
            .navigationTitle("Документы")
        }
        .task {
            await viewModel.loadDocuments()
        }
        .sheet(item: $activeEditor) { editor in
            editorScreen(for: editor)
        }
    }

    // MARK: - Components

    private var headerActions: some View {
        HStack(spacing: 12) {
            quickActionButton(title: "Счет", systemImage: "doc.text", tint: .blue) {
                activeEditor = .new(.invoice)
            }
            quickActionButton(title: "Акт", systemImage: "checkmark.seal", tint: .green) {
                activeEditor = .new(.act)
            }
            quickActionButton(title: "Накладная", systemImage: "shippingbox", tint: .orange) {
                activeEditor = .new(.deliveryNote)
            }
        }
    }

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
                        Button {
                            activeEditor = .edit(document)
                        } label: {
                            DocumentCardView(document: document)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func editorScreen(for editor: ActiveEditor) -> some View {
        switch editor {
        case .new(let type):
            DocumentEditorScreen(
                type: type,
                repository: repository,
                onSaved: reloadDocuments
            )

        case .edit(let document):
            DocumentEditorScreen(
                document: document,
                repository: repository,
                onSaved: reloadDocuments
            )
        }
    }

    private func reloadDocuments() {
        Task {
            await viewModel.reload()
        }
    }
}

// MARK: - Navigation

private enum ActiveEditor: Identifiable {
    case new(DocumentType)
    case edit(BusinessDocument)

    var id: String {
        switch self {
        case .new(let type):
            return "new-\(type.rawValue)"
        case .edit(let document):
            return "edit-\(document.id.uuidString)"
        }
    }
}
