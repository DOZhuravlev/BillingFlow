import SwiftUI

struct DealDetailScreen: View {
    @StateObject private var viewModel: DealDetailViewModel
    @State private var unavailableKind: DealDocumentKind?
    @State private var isDetailsSheetPresented = false

    init(viewModel: DealDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppColor.Brand.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                navigationHeader

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        heroSection
                        financeSummarySection
                        documentsSection
                        dealDetailsSection
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
        }
        .task { await viewModel.reload() }
        .sheet(isPresented: $isDetailsSheetPresented) {
            detailsEditorSheet
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .alert(item: $unavailableKind) { kind in
            Alert(
                title: Text(kind.title),
                message: Text("Создание этого документа появится на следующем этапе."),
                dismissButton: .default(Text("Понятно"))
            )
        }
    }
}

// MARK: - Header

private extension DealDetailScreen {
    var navigationHeader: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Button(action: viewModel.pop) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.16), in: Circle())
                    .overlay {
                        Circle().stroke(.white.opacity(0.24), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.deal.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(viewModel.deal.type.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.68))
            }
            .padding(.top, 1)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.sm)
    }
}

// MARK: - Hero

private extension DealDetailScreen {
    var heroSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Сумма сделки")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.64))

                Text(CurrencyFormatter.amountText(viewModel.deal.amount, currencyCode: viewModel.deal.currencyCode))
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            counterpartyBlock
            statusAndProgressBlock
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var counterpartyBlock: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Контрагент")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.64))

            Text(nonEmpty(viewModel.deal.counterparty.displayName, fallback: "Контрагент не указан"))
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white.opacity(0.94))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            if viewModel.deal.counterparty.taxID.isEmpty == false {
                Text("ИНН \(viewModel.deal.counterparty.taxID)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.68))
            }
        }
    }

    var statusAndProgressBlock: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                statusMenu

                if let dueDate = viewModel.deal.dueDate {
                    Text("до \(shortDate(dueDate))")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.68))
                }
            }

            ProgressView(value: viewModel.progress)
                .tint(.white)

            Text("Прогресс сделки · \(Int(viewModel.progress * 100))%")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.62))
        }
    }

    var statusMenu: some View {
        Menu {
            Button("Автоматически") { viewModel.useAutomaticStatus() }
            Divider()
            ForEach(DealStatus.allCases) { status in
                Button(status.title) { viewModel.selectStatus(status) }
            }
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(statusTint)
                    .frame(width: 8, height: 8)

                Text(viewModel.status.title)
                    .font(.system(size: 13, weight: .semibold))

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(.white.opacity(0.14), in: Capsule())
        }
    }

    var statusTint: Color {
        switch viewModel.status {
        case .overdue, .cancelled: return .red
        case .paid, .closed: return .green
        default: return .white
        }
    }
}

// MARK: - Finance

private extension DealDetailScreen {
    var financeSummarySection: some View {
        HStack(spacing: AppSpacing.sm) {
            BalanceSummaryCard(
                metric: FinanceMetric(
                    title: "Выставлено",
                    amount: CurrencyFormatter.amountText(viewModel.invoiceTotal, currencyCode: viewModel.deal.currencyCode),
                    style: .pending
                )
            )
            .frame(maxWidth: .infinity)

            BalanceSummaryCard(
                metric: FinanceMetric(
                    title: "Оплачено",
                    amount: CurrencyFormatter.amountText(viewModel.paidTotal, currencyCode: viewModel.deal.currencyCode),
                    style: .income
                )
            )
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Documents

private extension DealDetailScreen {
    var documentsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Пакет документов")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Text("\(createdDocumentsCount) из \(viewModel.documentSlots.count)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.64))
            }
            .padding(.horizontal, AppSpacing.sm)

            MaterialCard(cornerRadius: AppRadius.lg, padding: 0) {
                VStack(spacing: 0) {
                    ForEach(viewModel.documentSlots) { slot in
                        documentRow(slot)

                        if slot.id != viewModel.documentSlots.last?.id {
                            divider.padding(.leading, 56)
                        }
                    }
                }
            }
        }
    }

    var createdDocumentsCount: Int {
        viewModel.documentSlots.filter { $0.latestDocument != nil }.count
    }

    func documentRow(_ slot: DealDetailViewModel.DocumentSlot) -> some View {
        Button {
            if slot.latestDocument == nil && slot.kind.supportedDocumentType == nil {
                unavailableKind = slot.kind
            } else {
                viewModel.didTapSlot(slot)
            }
        } label: {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: slot.kind.iconName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(documentIconColor(slot))
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(slot.kind.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColor.Text.primary)

                    Text(documentSubtitle(slot))
                        .font(AppFont.Text.caption)
                        .foregroundStyle(AppColor.Text.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: AppSpacing.sm)

                Image(systemName: documentActionIcon(slot))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(documentIconColor(slot))
            }
            .padding(.horizontal, AppSpacing.md)
            .frame(minHeight: 66)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    func documentSubtitle(_ slot: DealDetailViewModel.DocumentSlot) -> String {
        if let document = slot.latestDocument {
            let number = document.number.isEmpty ? "без номера" : "№\(document.number)"
            return "\(document.type.displayName) \(number)"
        }
        return slot.kind.supportedDocumentType == nil ? "Будет доступно позже" : "Не создан"
    }

    func documentActionIcon(_ slot: DealDetailViewModel.DocumentSlot) -> String {
        if slot.latestDocument != nil { return "chevron.right" }
        return slot.kind.supportedDocumentType == nil ? "clock" : "plus.circle.fill"
    }

    func documentIconColor(_ slot: DealDetailViewModel.DocumentSlot) -> Color {
        if slot.latestDocument != nil { return .green }
        if slot.kind.supportedDocumentType == nil { return AppColor.Text.tertiary }
        return AppColor.Brand.primary
    }
}

// MARK: - Deal Details

private extension DealDetailScreen {
    var dealDetailsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Детали сделки")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, AppSpacing.sm)

            MaterialCard(cornerRadius: AppRadius.lg, padding: 0) {
                VStack(spacing: 0) {
                    detailRow(icon: "phone.fill", title: "Телефон", value: nonEmpty(viewModel.phone, fallback: "Не указан"))
                    divider.padding(.leading, 56)
                    detailRow(icon: "bell.fill", title: "Напоминание", value: reminderText)
                    divider.padding(.leading, 56)
                    detailRow(icon: "note.text", title: "Заметка", value: nonEmpty(viewModel.note, fallback: "Без заметки"), lineLimit: 3)
                    divider.padding(.leading, 56)

                    Button {
                        isDetailsSheetPresented = true
                    } label: {
                        Label("Изменить детали", systemImage: "pencil")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppColor.Brand.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    func detailRow(icon: String, title: String, value: String, lineLimit: Int = 1) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColor.Text.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFont.Text.caption)
                    .foregroundStyle(AppColor.Text.secondary)

                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(lineLimit)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .frame(minHeight: 58)
    }

    var reminderText: String {
        guard viewModel.isReminderEnabled else { return "Не задано" }
        return fullDate(viewModel.reminderDate)
    }
}

// MARK: - Details Editor

private extension DealDetailScreen {
    var detailsEditorSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    editorField("Телефон", text: $viewModel.phone, prompt: "+7")
                        .keyboardType(.phonePad)

                    editorField("Заметка", text: $viewModel.note, prompt: "Комментарий по сделке")

                    VStack(spacing: AppSpacing.sm) {
                        Toggle("Напомнить", isOn: $viewModel.isReminderEnabled)
                            .tint(AppColor.Brand.primary)

                        if viewModel.isReminderEnabled {
                            DatePicker("Дата и время", selection: $viewModel.reminderDate)
                                .datePickerStyle(.compact)
                        }
                    }
                    .padding(AppSpacing.md)
                    .background(Color.black.opacity(0.04), in: RoundedRectangle(cornerRadius: AppRadius.sm))

                    Button {
                        Task {
                            await viewModel.saveDetails()
                            isDetailsSheetPresented = false
                        }
                    } label: {
                        Text("Сохранить")
                            .font(AppFont.Control.button)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(AppColor.Brand.primary, in: RoundedRectangle(cornerRadius: AppRadius.sm))
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
            .navigationTitle("Детали сделки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") { isDetailsSheetPresented = false }
                }
            }
        }
    }

    func editorField(_ title: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Text.secondary)

            TextField(prompt, text: text, axis: title == "Заметка" ? .vertical : .horizontal)
                .lineLimit(title == "Заметка" ? 4 : 1)
                .padding(.horizontal, AppSpacing.md)
                .frame(minHeight: 46)
                .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: AppRadius.sm))
        }
    }
}

// MARK: - Helpers

private extension DealDetailScreen {
    var divider: some View {
        Rectangle()
            .fill(Color.black.opacity(0.07))
            .frame(height: 1)
    }

    func nonEmpty(_ value: String, fallback: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }

    func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: date)
    }

    func fullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM, HH:mm"
        return formatter.string(from: date)
    }
}
