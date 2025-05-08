import SwiftUI

struct DocumentEditorScreen: View {

    // MARK: - State

    @StateObject private var viewModel: DocumentEditorViewModel
    @State private var isPaymentReminderDesignEnabled = false
    @State private var paymentReminderDate = Date()

    // MARK: - Initialization

    init(viewModel: DocumentEditorViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColor.Brand.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        stepContent
                        errorView
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, 112)
                }
                .scrollIndicators(.hidden)
            }

            footer
        }
        .task {
            await viewModel.onAppear()
        }
    }
}

// MARK: - Header

private extension DocumentEditorScreen {
    var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                Button {
                    viewModel.didTapClose()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(.white.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.navigationTitle)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)

                    Text("\(viewModel.currentStep.rawValue + 1) из \(viewModel.steps.count) · \(viewModel.title(for: viewModel.currentStep))")
                        .font(AppFont.Text.caption)
                        .foregroundStyle(.white.opacity(0.72))
                }

                Spacer()
            }

            progressBar

            stepTabs
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.md)
        .padding(.bottom, AppSpacing.sm)
    }

    var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.36))

                Capsule()
                    .fill(.white)
                    .frame(width: proxy.size.width * viewModel.progress)
                    .shadow(color: .white.opacity(0.45), radius: 6, x: 0, y: 0)
            }
        }
        .frame(height: 6)
    }

    var stepTabs: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(viewModel.steps) { step in
                        Button {
                            viewModel.goToStep(step)
                        } label: {
                            Text(viewModel.title(for: step))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(step == viewModel.currentStep ? AppColor.Brand.primary : AppColor.Text.primary)
                                .padding(.horizontal, 12)
                                .frame(height: 30)
                                .background {
                                    Capsule()
                                        .fill(step == viewModel.currentStep ? .white : .white.opacity(0.62))
                                        .overlay {
                                            Capsule()
                                                .stroke(.white.opacity(step == viewModel.currentStep ? 0.9 : 0.28), lineWidth: 1)
                                        }
                                }
                        }
                        .id(step.id)
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .onAppear {
                proxy.scrollTo(viewModel.currentStep.id, anchor: .center)
            }
            .onChange(of: viewModel.currentStep) { step in
                withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                    proxy.scrollTo(step.id, anchor: .center)
                }
            }
        }
    }
}

// MARK: - Step Content

private extension DocumentEditorScreen {
    @ViewBuilder
    var stepContent: some View {
        switch viewModel.currentStep {
        case .start:
            startStep
        case .seller:
            partyStep(
                title: viewModel.sellerStepTitle,
                subtitle: viewModel.sellerStepSubtitle,
                searchTarget: .seller,
                party: viewModel.draft.seller,
                onSelect: viewModel.selectSeller,
                onUpdate: viewModel.updateSeller
            )
        case .buyer:
            partyStep(
                title: viewModel.buyerStepTitle,
                subtitle: viewModel.buyerStepSubtitle,
                searchTarget: .buyer,
                party: viewModel.draft.buyer,
                onSelect: viewModel.selectBuyer,
                onUpdate: viewModel.updateBuyer
            )
        case .details:
            detailsStep
        case .items:
            itemsStep
        case .notes:
            notesStep
        case .review:
            reviewStep
        }
    }

    var startStep: some View {
        VStack(spacing: AppSpacing.md) {
            sectionHeader(
                title: viewModel.startStepTitle,
                subtitle: viewModel.startStepSubtitle
            )

            MaterialCard {
                Button {
                    viewModel.useFreshDocument()
                } label: {
                    startChoiceRow(
                        title: viewModel.freshDocumentTitle,
                        subtitle: viewModel.freshDocumentSubtitle,
                        isSelected: viewModel.isFreshDocumentSelected
                    )
                }
                .buttonStyle(.plain)
            }

            if viewModel.recentDocumentTemplates.isEmpty == false {
                templatesSection
            }
        }
    }

    var templatesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(viewModel.templatesTitle)
                .font(AppFont.Text.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, AppSpacing.md)

            MaterialCard(cornerRadius: AppRadius.lg, padding: 0) {
                VStack(spacing: 0) {
                    ForEach(viewModel.recentDocumentTemplates.prefix(3)) { document in
                        Button {
                            viewModel.useTemplate(document)
                        } label: {
                            startChoiceRow(
                                title: "\(document.type.displayName) №\(document.number)",
                                subtitle: document.buyer.displayName.isEmpty ? "Контрагент не указан" : document.buyer.displayName,
                                trailingText: CurrencyFormatter.amountText(document.totals.total, currencyCode: document.currencyCode),
                                isSelected: viewModel.isTemplateSelected(document)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    func startChoiceRow(
        title: String,
        subtitle: String,
        trailingText: String? = nil,
        isSelected: Bool
    ) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(isSelected ? AppColor.Brand.primary : AppColor.Text.secondary)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColor.Text.primary)

                Text(subtitle)
                    .font(AppFont.Text.caption)
                    .foregroundStyle(AppColor.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            if let trailingText {
                Text(trailingText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
        }
        .padding(AppSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(isSelected ? AppColor.Brand.primary.opacity(0.08) : Color.clear)
        }
    }

    func partyStep(
        title: String,
        subtitle: String,
        searchTarget: DocumentEditorViewModel.PartySearchTarget,
        party: DocumentParty,
        onSelect: @escaping (DocumentParty) -> Void,
        onUpdate: @escaping (DocumentParty) -> Void
    ) -> some View {
        VStack(spacing: AppSpacing.md) {
            sectionHeader(title: title, subtitle: subtitle)

            if searchTarget == .seller {
                sellerOrganizationBlock
            } else {
                organizationSearchCard(target: searchTarget)

                if party.isEmpty {
                    buyerOrganizationSelectionCard(onSelect: onSelect)
                        .transition(.move(edge: .top).combined(with: .opacity))
                } else {
                    selectedBuyerDetailsCard(
                        party: party,
                        onUpdate: onUpdate
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: party)
        .onAppear {
            if searchTarget != .seller {
                viewModel.activateOrganizationSearch(target: searchTarget)
            }
        }
    }

    func buyerOrganizationSelectionCard(
        onSelect: @escaping (DocumentParty) -> Void
    ) -> some View {
        MaterialCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Контрагенты")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColor.Text.primary)

                    Text("Выберите организацию, с которой уже работали.")
                        .font(AppFont.Text.caption)
                        .foregroundStyle(AppColor.Text.secondary)
                }

                if viewModel.buyerOrganizationOptions.isEmpty {
                    HStack(alignment: .top, spacing: AppSpacing.sm) {
                        Image(systemName: "building.2")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppColor.Text.secondary)

                        Text("Контрагентов пока нет. Найдите организацию по ИНН или названию выше.")
                            .font(AppFont.Text.caption)
                            .foregroundStyle(AppColor.Text.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppSpacing.md)
                    .background(Color.black.opacity(0.035), in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                } else {
                    VStack(spacing: 0) {
                        ForEach(viewModel.buyerOrganizationOptions) { option in
                            Button {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                                    onSelect(option.party)
                                }
                            } label: {
                                buyerOrganizationRow(option)
                            }
                            .buttonStyle(.plain)

                            if option.id != viewModel.buyerOrganizationOptions.last?.id {
                                Rectangle()
                                    .fill(Color.black.opacity(0.07))
                                    .frame(height: 1)
                                    .padding(.leading, AppSpacing.md)
                            }
                        }
                    }
                    .background(Color.black.opacity(0.035), in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                }
            }
        }
    }

    func buyerOrganizationRow(_ option: DocumentEditorViewModel.OrganizationOption) -> some View {
        let isSelected = viewModel.selectedBuyerOrganizationOption?.id == option.id

        return HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(isSelected ? AppColor.Brand.primary : AppColor.Text.secondary)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 5) {
                Text(option.party.displayName.isEmpty ? "Без названия" : option.party.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text(option.subtitle)
                    .font(AppFont.Text.caption)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(2)

                if option.party.address.isEmpty == false {
                    Text(option.party.address)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColor.Text.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: AppSpacing.sm)
        }
        .padding(AppSpacing.md)
    }

    func selectedBuyerDetailsCard(
        party: DocumentParty,
        onUpdate: @escaping (DocumentParty) -> Void
    ) -> some View {
        VStack(spacing: AppSpacing.sm) {
            HStack {
                Text("Реквизиты плательщика")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        viewModel.resetBuyerSelection()
                    }
                } label: {
                    Text("Сменить")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppSpacing.sm)
                        .frame(height: 32)
                        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppSpacing.md)

            partyFieldsCard(
                party: party,
                onUpdate: onUpdate
            )
        }
    }

    func partyFieldsCard(
        party: DocumentParty,
        onUpdate: @escaping (DocumentParty) -> Void
    ) -> some View {
        MaterialCard {
            VStack(spacing: AppSpacing.md) {
                partyTextField("Название", value: party.displayName) { value in
                    var next = party
                    next.displayName = value
                    onUpdate(next)
                }
                partyTextField("ИНН", value: party.taxID) { value in
                    var next = party
                    next.taxID = value
                    onUpdate(next)
                }
                partyTextField("КПП / ОГРН", value: party.registrationNumber) { value in
                    var next = party
                    next.registrationNumber = value
                    onUpdate(next)
                }
                partyTextField("Адрес", value: party.address) { value in
                    var next = party
                    next.address = value
                    onUpdate(next)
                }
                partyTextField("Банк", value: party.bankName) { value in
                    var next = party
                    next.bankName = value
                    onUpdate(next)
                }
                partyTextField("Расчетный счет", value: party.bankAccount) { value in
                    var next = party
                    next.bankAccount = value
                    onUpdate(next)
                }
                partyTextField("БИК", value: party.bankCode) { value in
                    var next = party
                    next.bankCode = value
                    onUpdate(next)
                }
            }
        }
    }

    var sellerOrganizationBlock: some View {
        VStack(spacing: AppSpacing.md) {
            MaterialCard {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack(alignment: .top, spacing: AppSpacing.md) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(AppColor.Brand.primary)
                            .frame(width: 38, height: 38)
                            .background(AppColor.Brand.primary.opacity(0.10), in: Circle())

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Моя организация")
                                .font(AppFont.Text.caption)
                                .foregroundStyle(AppColor.Text.secondary)

                            Text(viewModel.draft.seller.displayName.isEmpty ? "Организация не выбрана" : viewModel.draft.seller.displayName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppColor.Text.primary)
                                .lineLimit(2)

                            Text(sellerOrganizationSubtitle)
                                .font(AppFont.Text.caption)
                                .foregroundStyle(AppColor.Text.secondary)
                                .lineLimit(2)
                        }

                        Spacer(minLength: AppSpacing.sm)
                    }

                    sellerOrganizationSelector

                    if viewModel.draft.seller.isEmpty == false {
                        sellerBankAccountSelector
                        sellerReadOnlyDetails
                    } else {
                        sellerEmptyState
                    }
                }
            }
        }
    }

    var sellerOrganizationSubtitle: String {
        var parts: [String] = []

        if viewModel.draft.seller.taxID.isEmpty == false {
            parts.append("ИНН \(viewModel.draft.seller.taxID)")
        }

        if viewModel.draft.seller.bankName.isEmpty == false {
            parts.append(viewModel.draft.seller.bankName)
        }

        if viewModel.draft.seller.bankAccount.isEmpty == false {
            parts.append(viewModel.draft.seller.bankAccount)
        }

        return parts.isEmpty ? "Добавьте свою организацию в профиле." : parts.joined(separator: " · ")
    }

    var sellerReadOnlyDetails: some View {
        VStack(spacing: 0) {
            readOnlyDetailRow(
                title: "Название",
                value: viewModel.draft.seller.displayName
            )
            readOnlyDivider
            readOnlyDetailRow(
                title: "ИНН",
                value: viewModel.draft.seller.taxID
            )
            readOnlyDivider
            readOnlyDetailRow(
                title: "КПП / ОГРН",
                value: viewModel.draft.seller.registrationNumber
            )
            readOnlyDivider
            readOnlyDetailRow(
                title: "Адрес",
                value: viewModel.draft.seller.address
            )
            readOnlyDivider
            readOnlyDetailRow(
                title: "Банк",
                value: viewModel.draft.seller.bankName
            )
            readOnlyDivider
            readOnlyDetailRow(
                title: "Расчетный счет",
                value: viewModel.draft.seller.bankAccount
            )
            readOnlyDivider
            readOnlyDetailRow(
                title: "БИК",
                value: viewModel.draft.seller.bankCode
            )
        }
        .background(Color.black.opacity(0.035), in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }

    var sellerEmptyState: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColor.Brand.primary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Своя организация не выбрана")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColor.Text.primary)

                Text("Добавьте организацию и банковский счет в профиле, затем вернитесь к созданию документа.")
                    .font(AppFont.Text.caption)
                    .foregroundStyle(AppColor.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    viewModel.openOrganizationProfile()
                } label: {
                    Label("Открыть профиль организации", systemImage: "arrow.right.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppSpacing.md)
                        .frame(height: 36)
                        .background(AppColor.Brand.primary, in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.Brand.primary.opacity(0.10), in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }

    func readOnlyDetailRow(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Text(title)
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Text.secondary)
                .frame(width: 104, alignment: .leading)

            Text(value.isEmpty ? "Не указано" : value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(value.isEmpty ? AppColor.Text.secondary : AppColor.Text.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 10)
    }

    var readOnlyDivider: some View {
        Rectangle()
            .fill(Color.black.opacity(0.06))
            .frame(height: 1)
            .padding(.leading, AppSpacing.md)
    }

    var sellerOrganizationSelector: some View {
        Menu {
            ForEach(viewModel.sellerOrganizationOptions) { option in
                Button {
                    viewModel.selectSellerOrganization(option)
                } label: {
                    Text(option.party.displayName.isEmpty ? "Без названия" : option.party.displayName)
                }
            }
        } label: {
            compactSelectorLabel(
                title: viewModel.sellerOrganizationOptions.isEmpty ? "Своих организаций пока нет" : "Сменить организацию",
                systemImage: "building.2"
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.sellerOrganizationOptions.isEmpty)
        .opacity(viewModel.sellerOrganizationOptions.isEmpty ? 0.55 : 1)
    }

    var sellerBankAccountSelector: some View {
        Menu {
            if viewModel.selectedSellerBankAccounts.isEmpty {
                Button("Счетов пока нет") { }
                    .disabled(true)
            } else {
                ForEach(viewModel.selectedSellerBankAccounts) { account in
                    Button {
                        viewModel.selectSellerBankAccount(account)
                    } label: {
                        Text("\(account.displayTitle) · \(account.displaySubtitle)")
                    }
                }
            }
        } label: {
            bankAccountSelectorLabel
        }
        .buttonStyle(.plain)
        .disabled(viewModel.selectedSellerBankAccounts.isEmpty)
        .opacity(viewModel.selectedSellerBankAccounts.isEmpty ? 0.55 : 1)
    }

    var sellerBankAccountTitle: String {
        if viewModel.draft.seller.bankName.isEmpty == false || viewModel.draft.seller.bankAccount.isEmpty == false {
            let bank = viewModel.draft.seller.bankName.isEmpty ? "Банк" : viewModel.draft.seller.bankName
            let account = viewModel.draft.seller.bankAccount.isEmpty ? "счет не указан" : viewModel.draft.seller.bankAccount
            return "\(bank) · \(account)"
        }

        return "Выбрать банк и счет"
    }

    func compactSelectorLabel(title: String, systemImage: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))

            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Spacer(minLength: AppSpacing.sm)

            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .bold))
        }
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(AppColor.Text.primary)
        .padding(.horizontal, AppSpacing.md)
        .frame(height: 44)
        .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
    }

    var bankAccountSelectorLabel: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.draft.seller.bankName.isEmpty ? "Выбрать банк" : viewModel.draft.seller.bankName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(viewModel.draft.seller.bankAccount.isEmpty ? "Расчетный счет не указан" : viewModel.draft.seller.bankAccount)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: AppSpacing.sm)

            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppColor.Text.secondary)
                .padding(.top, 3)
        }
        .padding(AppSpacing.md)
        .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
    }

    func organizationSearchCard(target: DocumentEditorViewModel.PartySearchTarget) -> some View {
        MaterialCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Поиск по ИНН или названию")
                        .font(AppFont.Text.caption)
                        .foregroundStyle(AppColor.Text.secondary)

                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppColor.Text.secondary)

                        TextField("7707083893 или Сбербанк", text: Binding(
                            get: { viewModel.organizationSearchQuery },
                            set: viewModel.updateOrganizationSearchQuery
                        ))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppColor.Text.primary)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.default)

                        if viewModel.isSearchingOrganizations {
                            ProgressView()
                                .tint(AppColor.Brand.primary)
                        } else if viewModel.organizationSearchQuery.isEmpty == false {
                            Button {
                                viewModel.resetOrganizationSearch()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(AppColor.Text.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .frame(height: 46)
                    .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
                }

                organizationSearchState(target: target)
            }
        }
    }

    @ViewBuilder
    func organizationSearchState(target: DocumentEditorViewModel.PartySearchTarget) -> some View {
        if let message = viewModel.organizationSearchErrorMessage {
            Text(message)
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Status.danger)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if viewModel.organizationSearchResults.isEmpty == false {
            VStack(spacing: 0) {
                ForEach(viewModel.organizationSearchResults) { suggestion in
                    Button {
                        viewModel.selectOrganizationSuggestion(suggestion, target: target)
                    } label: {
                        organizationSuggestionRow(suggestion)
                    }
                    .buttonStyle(.plain)

                    if suggestion.id != viewModel.organizationSearchResults.last?.id {
                        Rectangle()
                            .fill(Color.black.opacity(0.07))
                            .frame(height: 1)
                            .padding(.leading, AppSpacing.md)
                    }
                }
            }
            .background(Color.black.opacity(0.035), in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        } else if viewModel.organizationSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 &&
                    viewModel.organizationSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 {
            Text("Введите минимум 3 символа.")
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Text.secondary)
        }
    }

    func organizationSuggestionRow(_ suggestion: OrganizationSuggestion) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: "building.2")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColor.Brand.primary)
                .frame(width: 30, height: 30)
                .background(AppColor.Brand.primary.opacity(0.10), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(suggestion.shortName.isEmpty ? suggestion.name : suggestion.shortName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(2)

                Text(organizationSuggestionSubtitle(suggestion))
                    .font(AppFont.Text.caption)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(2)

                if suggestion.managerName.isEmpty == false {
                    Text(suggestion.managerName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColor.Text.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: AppSpacing.sm)

            Image(systemName: "checkmark.circle")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColor.Brand.primary)
        }
        .padding(AppSpacing.md)
    }

    func organizationSuggestionSubtitle(_ suggestion: OrganizationSuggestion) -> String {
        var parts = ["ИНН \(suggestion.inn)"]
        if suggestion.kpp.isEmpty == false {
            parts.append("КПП \(suggestion.kpp)")
        }
        if suggestion.address.isEmpty == false {
            parts.append(suggestion.address)
        }
        return parts.joined(separator: " · ")
    }

    func partyTextField(
        _ title: String,
        value: String,
        onChange: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Text.secondary)

            TextField(title, text: Binding(
                get: { value },
                set: onChange
            ))
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(AppColor.Text.primary)
            .textInputAutocapitalization(.never)
            .padding(.horizontal, AppSpacing.md)
            .frame(height: 46)
            .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
        }
    }

    var detailsStep: some View {
        VStack(spacing: AppSpacing.md) {
            sectionHeader(
                title: viewModel.detailsStepTitle,
                subtitle: viewModel.detailsStepSubtitle
            )

            MaterialCard {
                VStack(spacing: AppSpacing.md) {
                    partyTextField(viewModel.numberFieldTitle, value: viewModel.draft.number) {
                        viewModel.updateNumber($0)
                    }

                    dateSelectionRow
                }
            }
        }
    }

    var dateSelectionRow: some View {
        HStack(spacing: AppSpacing.md) {
            Text(viewModel.dateFieldTitle)
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Text.secondary)

            Spacer()

            DatePicker(
                "",
                selection: Binding(
                    get: { viewModel.draft.date },
                    set: viewModel.updateDate
                ),
                displayedComponents: .date
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .environment(\.locale, Locale(identifier: "ru_RU"))
        }
        .frame(minHeight: 44)
    }

    func itemVATSelector(for item: DocumentItem) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("НДС")
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Text.secondary)

            HStack(spacing: AppSpacing.xs) {
                vatButton(title: "Без НДС", rate: nil, item: item)
                vatButton(title: "НДС 10%", rate: 10, item: item)
                vatButton(title: "НДС 20%", rate: 20, item: item)
            }
            .padding(4)
            .background(Color.black.opacity(0.04), in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        }
    }

    func vatButton(title: String, rate: Decimal?, item: DocumentItem) -> some View {
        let displayedItem = currentItem(for: item)
        let isSelected = displayedItem.vatRate == rate

        return Button {
            viewModel.updateItemVATRate(id: item.id, vatRate: rate)
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? .white : AppColor.Text.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background {
                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                        .fill(isSelected ? AppColor.Brand.primary : Color.black.opacity(0.05))
                }
        }
        .buttonStyle(.plain)
    }

    var itemsStep: some View {
        VStack(spacing: AppSpacing.md) {
            sectionHeader(
                title: viewModel.itemsStepTitle,
                subtitle: viewModel.itemsStepSubtitle
            )

            VStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.draft.items) { item in
                    itemRow(item)
                }
            }

            Button {
                viewModel.addItem()
            } label: {
                Label(viewModel.draft.items.count > 1 ? "Добавить еще позицию" : "Еще одна позиция", systemImage: "plus.circle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.plain)

            totalCard
        }
    }

    func itemRow(_ item: DocumentItem) -> some View {
        let displayedItem = currentItem(for: item)

        return MaterialCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Позиция")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppColor.Text.primary)

                        Text(displayedItem.title.isEmpty ? viewModel.itemTitlePlaceholder : displayedItem.title)
                            .font(AppFont.Text.caption)
                            .foregroundStyle(AppColor.Text.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Text(CurrencyFormatter.amountText(displayedItem.amount, currencyCode: viewModel.draft.currencyCode))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppColor.Text.primary)

                    Button {
                        viewModel.removeItem(id: item.id)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.red.opacity(0.82))
                            .frame(width: 34, height: 34)
                            .background(Color.red.opacity(0.08), in: Circle())
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.itemTitleLabel)
                        .font(AppFont.Text.caption)
                        .foregroundStyle(AppColor.Text.secondary)

                    TextField(viewModel.itemTitlePlaceholder, text: Binding(
                        get: { currentItem(for: item).title },
                        set: { viewModel.updateItemTitle(id: item.id, title: $0) }
                    ))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColor.Text.primary)
                    .padding(.horizontal, AppSpacing.md)
                    .frame(height: 48)
                    .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
                }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Расчет")
                        .font(AppFont.Text.caption)
                        .foregroundStyle(AppColor.Text.secondary)

                    HStack(spacing: AppSpacing.sm) {
                        calculationField(title: "Кол-во") {
                            decimalField("", value: currentItem(for: item).quantity) {
                                viewModel.updateItemQuantity(id: item.id, quantity: $0)
                            }
                        }

                        calculationField(title: "Ед.") {
                            textField("", value: currentItem(for: item).unit) {
                                viewModel.updateItemUnit(id: item.id, unit: $0)
                            }
                        }

                        calculationField(title: "Цена") {
                            decimalField("", value: currentItem(for: item).price, hidesZero: true) {
                                viewModel.updateItemPrice(id: item.id, price: $0)
                            }
                        }
                    }
                }

                if viewModel.showsVATSelector {
                    itemVATSelector(for: item)
                }
            }
        }
    }

    func calculationField<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppColor.Text.secondary)

            content()
        }
    }

    func textField(
        _ title: String,
        value: String,
        onChange: @escaping (String) -> Void
    ) -> some View {
        TextField(title, text: Binding(get: { value }, set: onChange))
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(AppColor.Text.primary)
            .padding(.horizontal, AppSpacing.sm)
            .frame(height: 42)
            .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
    }

    func decimalField(
        _ title: String,
        value: Decimal,
        hidesZero: Bool = false,
        onChange: @escaping (Decimal) -> Void
    ) -> some View {
        InvoiceDecimalField(
            title: title,
            value: value,
            hidesZero: hidesZero,
            onChange: onChange
        )
    }

    var totalCard: some View {
        MaterialCard {
            VStack(spacing: AppSpacing.sm) {
                if viewModel.showsVATSelector {
                    ForEach(viewModel.vatBreakdownLines) { line in
                        amountLine(title: vatBreakdownTitle(for: line.rate), amount: line.amount)
                    }
                }
                Divider()
                amountLine(title: "Сумма позиций", amount: viewModel.totals.total, isTotal: true)
            }
        }
    }

    func vatBreakdownTitle(for rate: Decimal) -> String {
        "НДС \(decimalText(rate))%"
    }

    func amountLine(title: String, amount: Decimal, isTotal: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(isTotal ? AppFont.Text.headline : AppFont.Text.caption)
                .foregroundStyle(isTotal ? AppColor.Text.primary : AppColor.Text.secondary)

            Spacer()

            Text(CurrencyFormatter.amountText(amount, currencyCode: viewModel.draft.currencyCode))
                .font(isTotal ? .system(size: 20, weight: .bold) : .system(size: 14, weight: .semibold))
                .foregroundStyle(AppColor.Text.primary)
        }
    }

    var notesStep: some View {
        VStack(spacing: AppSpacing.md) {
            sectionHeader(
                title: "Оплата и заметка",
                subtitle: "Добавьте внутреннюю заметку и настройте будущие напоминания об оплате."
            )

            paymentReminderDesignCard

            MaterialCard {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Внутренняя заметка")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppColor.Text.primary)

                        Text("Эта заметка нужна только вам и не попадет в документ.")
                            .font(AppFont.Text.caption)
                            .foregroundStyle(AppColor.Text.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    TextEditor(text: Binding(
                        get: { viewModel.draft.notes },
                        set: viewModel.updateNotes
                    ))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColor.Text.primary)
                    .frame(minHeight: 150)
                    .scrollContentBackground(.hidden)
                    .padding(AppSpacing.sm)
                    .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
                }
            }
        }
    }

    var paymentReminderDesignCard: some View {
        MaterialCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack(alignment: .top, spacing: AppSpacing.md) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColor.Brand.primary)
                        .frame(width: 42, height: 42)
                        .background(AppColor.Brand.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Напомнить об оплате")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppColor.Text.primary)

                        Text("Выберите, когда отправить пуш-напоминание об оплате.")
                            .font(AppFont.Text.caption)
                            .foregroundStyle(AppColor.Text.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: AppSpacing.sm)

                    Toggle("", isOn: $isPaymentReminderDesignEnabled)
                        .labelsHidden()
                        .tint(AppColor.Brand.primary)
                }

                if isPaymentReminderDesignEnabled {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Дата и время напоминания")
                            .font(AppFont.Text.caption)
                            .foregroundStyle(AppColor.Text.secondary)

                        HStack(spacing: AppSpacing.sm) {
                            reminderPickerBox(
                                title: "Время",
                                systemImage: "clock",
                                components: .hourAndMinute
                            )

                            reminderPickerBox(
                                title: "Дата",
                                systemImage: "calendar",
                                components: .date
                            )
                        }
                    }
                }
            }
        }
    }

    func reminderPickerBox(
        title: String,
        systemImage: String,
        components: DatePickerComponents
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.Brand.primary)

                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.Text.secondary)
            }

            DatePicker(
                "",
                selection: $paymentReminderDate,
                displayedComponents: components
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
    }

    var reviewStep: some View {
        VStack(spacing: AppSpacing.md) {
            sectionHeader(
                title: viewModel.reviewStepTitle,
                subtitle: viewModel.reviewStepSubtitle
            )

            MaterialCard {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    amountLine(title: "Итого", amount: viewModel.totals.total, isTotal: true)
                    reviewLine("Номер", viewModel.draft.number)
                    reviewLine(viewModel.sellerReviewTitle, viewModel.draft.seller.displayName)
                    reviewLine(viewModel.buyerReviewTitle, viewModel.draft.buyer.displayName)
                    reviewLine("Позиций", "\(viewModel.draft.items.count)")
                }
            }

            MaterialCard(cornerRadius: AppRadius.lg, padding: 0) {
                VStack(spacing: 0) {
                    ForEach(viewModel.draft.items) { item in
                        HStack(spacing: AppSpacing.sm) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title.isEmpty ? "Без названия" : item.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppColor.Text.primary)

                                Text("\(decimalText(item.quantity)) \(item.unit) × \(CurrencyFormatter.amountText(item.price, currencyCode: viewModel.draft.currencyCode))")
                                    .font(AppFont.Text.caption)
                                    .foregroundStyle(AppColor.Text.secondary)
                            }

                            Spacer()

                            Text(CurrencyFormatter.amountText(item.amount, currencyCode: viewModel.draft.currencyCode))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(AppColor.Text.primary)
                        }
                        .padding(AppSpacing.md)
                    }
                }
            }
        }
    }

    func reviewLine(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Text.secondary)
                .frame(width: 86, alignment: .leading)

            Text(value.isEmpty ? "Не указано" : value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColor.Text.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Footer

private extension DocumentEditorScreen {
    var footer: some View {
        VStack {
            Spacer()

            HStack(spacing: AppSpacing.sm) {
                if viewModel.currentStep != .start {
                    Button {
                        viewModel.goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(AppColor.Text.primary)
                            .frame(width: 48, height: 48)
                            .background(Color.white, in: Circle())
                    }
                    .buttonStyle(.plain)
                }

                if viewModel.currentStep == .review {
                    Button {
                        viewModel.didTapPreview()
                    } label: {
                        Label("Дальше", systemImage: "arrow.right.circle.fill")
                            .font(AppFont.Control.button)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(AppColor.Brand.primary, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.canSave == false)
                    .opacity(viewModel.canSave ? 1 : 0.45)
                } else {
                    Button {
                        viewModel.goForward()
                    } label: {
                        Label("Дальше", systemImage: "arrow.right.circle.fill")
                            .font(AppFont.Control.button)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(AppColor.Brand.primary, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.canMoveForward == false)
                    .opacity(viewModel.canMoveForward ? 1 : 0.45)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.md)
            .background(.ultraThinMaterial)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

// MARK: - Common Views

private extension DocumentEditorScreen {
    func currentItem(for item: DocumentItem) -> DocumentItem {
        viewModel.draft.items.first(where: { $0.id == item.id }) ?? item
    }

    func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(AppFont.Text.caption)
                .foregroundStyle(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    var errorView: some View {
        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .font(AppFont.Text.caption)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.md)
        }
    }

    func decimalText(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        return DocumentHTMLRenderer.amountFormatter.string(from: number) ?? number.stringValue
    }

}

private struct InvoiceDecimalField: View {
    let title: String
    let value: Decimal
    let hidesZero: Bool
    let onChange: (Decimal) -> Void

    @State private var text: String
    @FocusState private var isFocused: Bool

    init(
        title: String,
        value: Decimal,
        hidesZero: Bool = false,
        onChange: @escaping (Decimal) -> Void
    ) {
        self.title = title
        self.value = value
        self.hidesZero = hidesZero
        self.onChange = onChange
        _text = State(initialValue: Self.displayText(for: value, hidesZero: hidesZero))
    }

    var body: some View {
        TextField(title, text: $text)
            .keyboardType(.decimalPad)
            .focused($isFocused)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(AppColor.Text.primary)
            .padding(.horizontal, AppSpacing.sm)
            .frame(height: 42)
            .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
            .onChange(of: text) { newValue in
                onChange(Self.decimalValue(from: newValue))
            }
            .onChange(of: value) { newValue in
                guard isFocused == false else { return }
                text = Self.displayText(for: newValue, hidesZero: hidesZero)
            }
            .onChange(of: isFocused) { newValue in
                if newValue == false {
                    text = Self.displayText(for: value, hidesZero: hidesZero)
                }
            }
    }
}

private extension InvoiceDecimalField {
    static func displayText(for value: Decimal, hidesZero: Bool) -> String {
        if hidesZero && value == 0 {
            return ""
        }

        let number = NSDecimalNumber(decimal: value)
        return DocumentHTMLRenderer.amountFormatter.string(from: number) ?? number.stringValue
    }

    static func decimalValue(from text: String) -> Decimal {
        let normalized = text
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")

        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX")) ?? 0
    }
}
