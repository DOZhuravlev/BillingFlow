import SwiftUI

struct DealCreateScreen: View {
    @StateObject private var viewModel: DealCreateViewModel

    init(viewModel: DealCreateViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppColor.Brand.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ScrollView {
                    stepContent
                        .padding(AppSpacing.md)
                        .padding(.bottom, 100)
                }
                .scrollIndicators(.hidden)
            }

            footer
        }
        .task { await viewModel.load() }
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: viewModel.step)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Button(action: viewModel.back) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(.white.opacity(0.16), in: Circle())
                }
                .buttonStyle(.plain)

                Text("Новая сделка")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
            }

            ProgressView(value: Double(viewModel.step.rawValue + 1), total: 3)
                .tint(.white)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.step {
        case .type: typeStep
        case .counterparty: counterpartyStep
        case .details: detailsStep
        }
    }

    private var typeStep: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            stepTitle("Тип сделки", subtitle: "Подберем подходящий комплект документов")
            MaterialCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(DealType.allCases) { type in
                        choiceRow(title: type.title, icon: type.iconName, selected: viewModel.type == type) {
                            viewModel.type = type
                        }
                        if type != DealType.allCases.last { divider }
                    }
                }
            }
        }
    }

    private var counterpartyStep: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            stepTitle("Контрагент", subtitle: "С кем оформляем сделку")
            if viewModel.counterparties.isEmpty {
                MaterialCard { Text("Контрагентов пока нет. Сначала создайте документ с организацией или добавьте ее в профиле контрагента.").font(AppFont.Text.caption).foregroundStyle(AppColor.Text.secondary) }
            } else {
                MaterialCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(viewModel.counterparties) { organization in
                            choiceRow(
                                title: organization.party.displayName,
                                subtitle: organization.party.taxID.isEmpty ? "ИНН не указан" : "ИНН \(organization.party.taxID)",
                                icon: "building.2.fill",
                                selected: viewModel.counterparty == organization.party
                            ) { viewModel.selectCounterparty(organization) }
                            if organization.id != viewModel.counterparties.last?.id { divider }
                        }
                    }
                }
            }
        }
    }

    private var detailsStep: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            stepTitle("Параметры сделки", subtitle: "Название, плановая сумма и срок")
            MaterialCard {
                VStack(spacing: AppSpacing.md) {
                    field("Название сделки", text: $viewModel.title, prompt: "Например, разработка сайта")
                    field("Сумма", text: $viewModel.amountText, prompt: "0")
                        .keyboardType(.decimalPad)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Срок оплаты").font(AppFont.Text.caption).foregroundStyle(AppColor.Text.secondary)
                        DatePicker("", selection: $viewModel.dueDate, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            if let error = viewModel.errorMessage {
                Text(error).font(AppFont.Text.caption).foregroundStyle(.white)
            }
        }
    }

    private var footer: some View {
        VStack {
            Spacer()
            Button {
                Task { await viewModel.next() }
            } label: {
                Text(viewModel.step == .details ? "Создать сделку" : "Дальше")
                    .font(AppFont.Control.button)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(AppColor.Brand.primary, in: RoundedRectangle(cornerRadius: AppRadius.md))
            }
            .disabled(viewModel.canContinue == false || viewModel.isSaving)
            .opacity(viewModel.canContinue ? 1 : 0.45)
            .padding(AppSpacing.md)
            .background(.ultraThinMaterial)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private func stepTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
            Text(subtitle).font(AppFont.Text.caption).foregroundStyle(.white.opacity(0.72))
        }
    }

    private func choiceRow(title: String, subtitle: String? = nil, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: icon).font(.system(size: 17, weight: .semibold)).frame(width: 24)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(AppColor.Text.primary)
                    if let subtitle { Text(subtitle).font(AppFont.Text.caption).foregroundStyle(AppColor.Text.secondary) }
                }
                Spacer()
                Circle().stroke(selected ? Color.green : Color.black.opacity(0.2), lineWidth: 2).frame(width: 22, height: 22).overlay { if selected { Circle().fill(Color.green).frame(width: 12, height: 12) } }
            }
            .padding(AppSpacing.md)
        }
        .buttonStyle(.plain)
    }

    private func field(_ title: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(AppFont.Text.caption).foregroundStyle(AppColor.Text.secondary)
            TextField(prompt, text: text).padding(.horizontal, AppSpacing.md).frame(height: 46).background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: AppRadius.sm))
        }
    }

    private var divider: some View { Rectangle().fill(Color.black.opacity(0.07)).frame(height: 1).padding(.leading, 56) }
}
