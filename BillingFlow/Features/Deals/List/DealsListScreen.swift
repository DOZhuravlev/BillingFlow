import SwiftUI

struct DealsListScreen: View {
    @StateObject private var viewModel: DealsListViewModel

    init(viewModel: DealsListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppColor.Brand.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                content
            }
        }
        .task { await viewModel.loadIfNeeded() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Сделки")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                Text("Пакеты документов и расчеты")
                    .font(AppFont.Text.caption)
                    .foregroundStyle(.white.opacity(0.68))
            }

            Spacer()

            Button(action: viewModel.didTapCreate) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.16), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            Spacer()
            ProgressView().tint(.white)
            Spacer()
        case .empty:
            emptyState
        case .error(let message):
            Spacer()
            Text(message)
                .font(AppFont.Text.caption)
                .foregroundStyle(.white.opacity(0.8))
                .padding()
            Spacer()
        case .loaded:
            ScrollView {
                LazyVStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.items) { item in
                        dealCard(item)
                            .onTapGesture { viewModel.didTapDeal(item.deal) }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppLayout.floatingTabBarBottomInset)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()
            Image(systemName: "briefcase.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))
            Text("Сделок пока нет")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
            Button("Создать сделку", action: viewModel.didTapCreate)
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(AppColor.Text.primary)
            Spacer()
        }
    }

    private func dealCard(_ item: DealsListViewModel.Item) -> some View {
        MaterialCard(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.deal.counterparty.displayName.isEmpty ? "Контрагент не указан" : item.deal.counterparty.displayName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColor.Text.primary)
                        .lineLimit(2)

                    Spacer(minLength: AppSpacing.sm)

                    Text(CurrencyFormatter.amountText(item.deal.amount, currencyCode: item.deal.currencyCode))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColor.Text.primary)
                        .lineLimit(1)
                }

                Text(item.deal.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(2)

                Text(statusLine(item))
                    .font(AppFont.Text.caption)
                    .foregroundStyle(statusColor(item.status))

                Text(documentSummary(item.documents))
                    .font(AppFont.Text.caption)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(2)
            }
        }
    }

    private func statusLine(_ item: DealsListViewModel.Item) -> String {
        let dueText = item.deal.dueDate.map { " · до \(shortDate($0))" } ?? ""
        return item.status.title + dueText
    }

    private func documentSummary(_ documents: [BusinessDocument]) -> String {
        let readyDocuments = documents.filter { $0.status != .draft }
        let hasInvoice = readyDocuments.contains { $0.type == .invoice }
        let hasAct = readyDocuments.contains { $0.type == .act }
        return [
            hasInvoice ? "Счет" : "Нет счета",
            "Нет договора",
            hasAct ? "Акт" : "Нет акта"
        ].joined(separator: " · ")
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: date)
    }

    private func statusColor(_ status: DealStatus) -> Color {
        switch status {
        case .overdue, .cancelled: return .red
        case .paid, .closed: return .green
        default: return AppColor.Text.secondary
        }
    }
}
