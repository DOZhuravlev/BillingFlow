import SwiftUI

struct DocumentEditorScreen: View {

    // MARK: - State

    @StateObject private var viewModel: DocumentEditorViewModel

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
            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
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
                organizationMenu(onSelect: onSelect)
                organizationSearchCard(target: searchTarget)
            }

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
        .onAppear {
            viewModel.activateOrganizationSearch(target: searchTarget)
        }
    }

    func organizationMenu(onSelect: @escaping (DocumentParty) -> Void) -> some View {
        Menu {
            ForEach(viewModel.organizationOptions) { option in
                Button {
                    onSelect(option.party)
                } label: {
                    Text(option.party.displayName)
                }
            }
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "building.2.fill")
                Text(viewModel.organizationOptions.isEmpty ? "Организаций пока нет" : "Выбрать из организаций")
                Spacer()
                Image(systemName: "chevron.down")
            }
            .font(AppFont.Control.button)
            .foregroundStyle(.white)
            .padding(.horizontal, AppSpacing.md)
            .frame(height: 48)
            .background(AppColor.Brand.primary, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.organizationOptions.isEmpty)
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
                    }
                }
            }

            organizationSearchCard(target: .seller)
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

        return parts.isEmpty ? "Добавьте свою организацию через поиск или заполните вручную." : parts.joined(separator: " · ")
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
            selectorLabel(
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
            selectorLabel(
                title: sellerBankAccountTitle,
                systemImage: "creditcard"
            )
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

    func selectorLabel(title: String, systemImage: String) -> some View {
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
        .font(AppFont.Control.button)
        .foregroundStyle(AppColor.Text.primary)
        .padding(.horizontal, AppSpacing.md)
        .frame(height: 44)
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

                    DatePicker(
                        viewModel.dateFieldTitle,
                        selection: Binding(
                            get: { viewModel.draft.date },
                            set: viewModel.updateDate
                        ),
                        displayedComponents: .date
                    )
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColor.Text.primary)

                    partyTextField("Валюта", value: viewModel.draft.currencyCode) {
                        viewModel.updateCurrencyCode($0)
                    }

                    if viewModel.showsVATSelector {
                        vatSelector
                    }
                }
            }
        }
    }

    var vatSelector: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("НДС")
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Text.secondary)

            HStack(spacing: AppSpacing.xs) {
                vatButton(title: "Без НДС", rate: nil)
                vatButton(title: "10%", rate: 10)
                vatButton(title: "20%", rate: 20)
            }
        }
    }

    func vatButton(title: String, rate: Decimal?) -> some View {
        let isSelected = viewModel.selectedVATRate == rate

        return Button {
            viewModel.updateVATRate(rate)
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
                Label("Добавить позицию", systemImage: "plus.circle.fill")
                    .font(AppFont.Control.button)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(AppColor.Brand.primary, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
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
                            decimalField("", value: currentItem(for: item).price) {
                                viewModel.updateItemPrice(id: item.id, price: $0)
                            }
                        }
                    }
                }

                if viewModel.showsVATSelector {
                    HStack {
                        Text(displayedItem.vatRate.map { "НДС \(decimalText($0))%" } ?? "Без НДС")
                            .font(AppFont.Text.caption)
                            .foregroundStyle(AppColor.Text.secondary)
                    }
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
        onChange: @escaping (Decimal) -> Void
    ) -> some View {
        InvoiceDecimalField(
            title: title,
            value: value,
            onChange: onChange
        )
    }

    var totalCard: some View {
        MaterialCard {
            VStack(spacing: AppSpacing.sm) {
                amountLine(title: "Подытог", amount: viewModel.totals.subtotal)
                if viewModel.showsVATSelector {
                    amountLine(title: "НДС", amount: viewModel.totals.vatAmount)
                }
                Divider()
                amountLine(title: "Итого", amount: viewModel.totals.total, isTotal: true)
            }
        }
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
                title: "Комментарий",
                subtitle: "Добавьте назначение платежа, срок оплаты или внутреннюю заметку."
            )

            MaterialCard {
                TextEditor(text: Binding(
                    get: { viewModel.draft.notes },
                    set: viewModel.updateNotes
                ))
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppColor.Text.primary)
                .frame(minHeight: 180)
                .scrollContentBackground(.hidden)
            }
        }
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
    let onChange: (Decimal) -> Void

    @State private var text: String
    @FocusState private var isFocused: Bool

    init(
        title: String,
        value: Decimal,
        onChange: @escaping (Decimal) -> Void
    ) {
        self.title = title
        self.value = value
        self.onChange = onChange
        _text = State(initialValue: Self.displayText(for: value))
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
                text = Self.displayText(for: newValue)
            }
            .onChange(of: isFocused) { newValue in
                if newValue == false {
                    text = Self.displayText(for: value)
                }
            }
    }
}

private extension InvoiceDecimalField {
    static func displayText(for value: Decimal) -> String {
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
