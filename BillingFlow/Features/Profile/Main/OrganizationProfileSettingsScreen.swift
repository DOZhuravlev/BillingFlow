import SwiftUI

struct OrganizationProfileSettingsScreen: View {

    // MARK: - State

    @StateObject private var viewModel: OrganizationProfileSettingsViewModel
    @State private var showsDeleteConfirmation = false
    @State private var isOrganizationDetailsExpanded = false
    @State private var expandedBankAccountIDs = Set<UUID>()
    private let onBack: () -> Void

    // MARK: - Initialization

    init(
        viewModel: OrganizationProfileSettingsViewModel,
        onBack: @escaping () -> Void = { }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onBack = onBack
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColor.Brand.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                navigationBar

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        organizationsSection

                        if viewModel.isSearchVisible {
                            searchSection
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        formSection
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, AppLayout.floatingTabBarBottomInset)
                }
                .scrollIndicators(.hidden)
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: viewModel.isSearchVisible)
        .task {
            await viewModel.load()
        }
        .alert("Удалить организацию?", isPresented: $showsDeleteConfirmation) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                Task {
                    await viewModel.deleteSelectedOrganization()
                }
            }
        } message: {
            Text("Она больше не будет подставляться при создании документов.")
        }
    }
}

// MARK: - Navigation

private extension OrganizationProfileSettingsScreen {
    var navigationBar: some View {
        HStack(spacing: AppSpacing.md) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.16), in: Circle())
            }
            .buttonStyle(.plain)

            Text("Мои организации")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }
}

// MARK: - Organizations

private extension OrganizationProfileSettingsScreen {
    var organizationsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            if viewModel.isLoading {
                loadingCard
            } else if viewModel.organizations.isEmpty {
                emptyOrganizationsCard
            } else {
                MaterialCard(cornerRadius: AppRadius.lg, padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(viewModel.organizations) { organization in
                            organizationRow(organization)

                            if organization.id != viewModel.organizations.last?.id {
                                divider
                                    .padding(.leading, AppSpacing.md)
                            }
                        }

                        divider
                            .padding(.leading, AppSpacing.md)

                        addOrganizationRow
                    }
                }
            }
        }
    }

    func organizationRow(_ organization: Organization) -> some View {
        let isSelected = organization.id == viewModel.selectedOrganizationID

        return HStack(alignment: .center, spacing: AppSpacing.md) {
            Button {
                Task {
                    await viewModel.setDefaultOrganization(organization)
                }
            } label: {
                organizationSelectionIndicator(isSelected: organization.isDefault)
            }
            .buttonStyle(.plain)

            Button {
                viewModel.selectOrganization(organization)
            } label: {
                HStack(alignment: .center, spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(organization.party.displayName.isEmpty ? "Без названия" : organization.party.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColor.Text.primary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(organization.party.taxID.isEmpty ? "ИНН не указан" : "ИНН \(organization.party.taxID)")
                        .font(AppFont.Text.caption)
                        .foregroundStyle(AppColor.Text.secondary)
                        .lineLimit(1)
                }

                    Spacer(minLength: AppSpacing.sm)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background {
            if isSelected {
                Rectangle()
                    .fill(Color.blue.opacity(0.07))
            }
        }
    }

    func organizationSelectionIndicator(isSelected: Bool) -> some View {
        Circle()
            .stroke(isSelected ? Color.blue.opacity(0.9) : Color.black.opacity(0.22), lineWidth: 2)
            .frame(width: 22, height: 22)
            .overlay {
                if isSelected {
                    Circle()
                        .fill(Color.blue.opacity(0.9))
                        .frame(width: 12, height: 12)
                }
            }
    }

    var addOrganizationRow: some View {
        Button {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                viewModel.startNewOrganization()
                isOrganizationDetailsExpanded = true
            }
        } label: {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppColor.Brand.primary)
                    .frame(width: 44, height: 44)
                    .background {
                        RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                            .fill(AppColor.Brand.primary.opacity(0.12))
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Добавить организацию")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColor.Text.primary)

                    Text("Найти по ИНН или заполнить вручную")
                        .font(AppFont.Text.caption)
                        .foregroundStyle(AppColor.Text.secondary)
                }

                Spacer(minLength: AppSpacing.sm)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.md)
        }
        .buttonStyle(.plain)
    }

    var loadingCard: some View {
        MaterialCard {
            HStack(spacing: AppSpacing.sm) {
                ProgressView()
                    .tint(AppColor.Brand.primary)

                Text("Загружаем организации")
                    .font(AppFont.Text.caption)
                    .foregroundStyle(AppColor.Text.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    var emptyOrganizationsCard: some View {
        MaterialCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Добавьте первую свою организацию")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColor.Text.primary)

                Text("Можно заполнить вручную или найти данные по ИНН.")
                    .font(AppFont.Text.caption)
                    .foregroundStyle(AppColor.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                        viewModel.startNewOrganization()
                        isOrganizationDetailsExpanded = true
                    }
                } label: {
                    Label("Добавить организацию", systemImage: "plus")
                        .font(AppFont.Control.button)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background {
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .fill(AppColor.Brand.primary)
                        }
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Search

private extension OrganizationProfileSettingsScreen {
    var searchSection: some View {
        MaterialCard(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                sectionHeader(
                    title: "Найти по ИНН или названию",
                    subtitle: "Данные организации заполнятся автоматически"
                )

                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColor.Text.secondary)

                    TextField("7707083893 или Сбербанк", text: Binding(
                        get: { viewModel.searchQuery },
                        set: viewModel.updateSearchQuery
                    ))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColor.Text.primary)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                    if viewModel.isSearching {
                        ProgressView()
                            .tint(AppColor.Brand.primary)
                    } else if viewModel.searchQuery.isEmpty == false {
                        Button {
                            viewModel.resetSearch()
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

                searchState
            }
        }
    }

    @ViewBuilder
    var searchState: some View {
        if let message = viewModel.searchErrorMessage {
            Text(message)
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Text.secondary)
        } else if viewModel.searchResults.isEmpty == false {
            VStack(spacing: 0) {
                ForEach(viewModel.searchResults) { suggestion in
                    Button {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                            viewModel.selectSuggestion(suggestion)
                            isOrganizationDetailsExpanded = true
                        }
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(suggestion.preferredDisplayName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppColor.Text.primary)
                                    .lineLimit(1)

                                if suggestion.shortName.isEmpty == false,
                                   suggestion.name != suggestion.shortName {
                                    Text(suggestion.name)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(AppColor.Text.secondary)
                                        .lineLimit(1)
                                }

                                Text([suggestion.inn.isEmpty ? nil : "ИНН \(suggestion.inn)", suggestion.address.isEmpty ? nil : suggestion.address].compactMap { $0 }.joined(separator: " · "))
                                    .font(AppFont.Text.caption)
                                    .foregroundStyle(AppColor.Text.secondary)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: AppSpacing.sm)

                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(AppColor.Brand.primary)
                        }
                        .padding(.vertical, AppSpacing.sm)
                    }
                    .buttonStyle(.plain)

                    if suggestion.id != viewModel.searchResults.last?.id {
                        divider
                    }
                }
            }
        }
    }
}

// MARK: - Form

private extension OrganizationProfileSettingsScreen {
    var formSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            organizationDetailsCard
            bankAccountsCard
            actionsCard
        }
    }

    var organizationDetailsCard: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                    isOrganizationDetailsExpanded.toggle()
                }
            } label: {
                organizationDetailsSummary
            }
            .buttonStyle(.plain)

            if isOrganizationDetailsExpanded {
                divider

                organizationDetailsFields
                    .padding(AppSpacing.md)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
    }

    var organizationDetailsSummary: some View {
        HStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Реквизиты организации")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColor.Text.primary)

                Text(organizationDetailsSubtitle)
                    .font(AppFont.Text.caption)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: AppSpacing.sm)

            Image(systemName: isOrganizationDetailsExpanded ? "chevron.down" : "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppColor.Text.secondary)
        }
        .padding(AppSpacing.md)
        .contentShape(Rectangle())
    }

    var organizationDetailsSubtitle: String {
        let name = viewModel.draft.party.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let taxID = viewModel.draft.party.taxID.trimmingCharacters(in: .whitespacesAndNewlines)

        if name.isEmpty && taxID.isEmpty {
            return "Заполните данные организации"
        }
        if taxID.isEmpty {
            return name
        }
        return "ИНН \(taxID)"
    }

    var organizationDetailsFields: some View {
        VStack(spacing: AppSpacing.md) {
            formField("Название", value: viewModel.draft.party.displayName) {
                viewModel.updatePartyField(.displayName, value: $0)
            }

            formField("Полное наименование", value: viewModel.draft.party.fullName) {
                viewModel.updatePartyField(.fullName, value: $0)
            }

            formField("ИНН", value: viewModel.draft.party.taxID) {
                viewModel.updatePartyField(.taxID, value: $0)
            }
            .keyboardType(.numberPad)

            formField("КПП / ОГРН", value: viewModel.draft.party.registrationNumber) {
                viewModel.updatePartyField(.registrationNumber, value: $0)
            }

            formField("Юридический адрес", value: viewModel.draft.party.address) {
                viewModel.updatePartyField(.address, value: $0)
            }

            formField("Руководитель", value: viewModel.draft.party.contactName) {
                viewModel.updatePartyField(.contactName, value: $0)
            }

            formField("Телефон", value: viewModel.draft.party.phone) {
                viewModel.updatePartyField(.phone, value: $0)
            }
            .keyboardType(.phonePad)

            formField("Email", value: viewModel.draft.party.email) {
                viewModel.updatePartyField(.email, value: $0)
            }
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
        }
    }

    var bankAccountsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(
                title: "Банковские реквизиты",
                subtitle: "Расчетные счета, БИК и корреспондентские счета",
                onDarkBackground: true
            )

            VStack(spacing: AppSpacing.md) {
                ForEach(viewModel.draft.bankAccounts) { account in
                    bankAccountCard(account)
                }

                addBankAccountButton
            }
        }
    }

    var addBankAccountButton: some View {
        Button {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                viewModel.addBankAccount()
                if let accountID = viewModel.draft.bankAccounts.last?.id {
                    expandedBankAccountIDs.insert(accountID)
                }
            }
        } label: {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColor.Brand.primary)
                    .frame(width: 40, height: 40)
                    .background {
                        RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                            .fill(AppColor.Brand.primary.opacity(0.12))
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Добавить банковский счет")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColor.Text.primary)

                    Text("Для счетов в разных банках или филиалах")
                        .font(AppFont.Text.caption)
                        .foregroundStyle(AppColor.Text.secondary)
                }

                Spacer(minLength: AppSpacing.sm)
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    func bankAccountCard(_ account: OrganizationBankAccount) -> some View {
        let isDefault = account.id == viewModel.draft.defaultBankAccountID
        let isExpanded = expandedBankAccountIDs.contains(account.id)

        return VStack(spacing: 0) {
            bankAccountHeader(account, isDefault: isDefault, isExpanded: isExpanded)

            if isExpanded {
                divider
                    .transition(.opacity)

                bankAccountDetails(account)
                .padding(AppSpacing.md)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
    }

    func bankAccountHeader(
        _ account: OrganizationBankAccount,
        isDefault: Bool,
        isExpanded: Bool
    ) -> some View {
        HStack(alignment: .center, spacing: AppSpacing.md) {
            Button {
                viewModel.setDefaultBankAccount(id: account.id)
            } label: {
                bankAccountSelectionIndicator(isSelected: isDefault)
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                    toggleBankAccountDetails(account.id)
                }
            } label: {
                bankAccountSummary(account, isExpanded: isExpanded)
            }
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.md)
    }

    func bankAccountSelectionIndicator(isSelected: Bool) -> some View {
        Circle()
            .stroke(isSelected ? Color.blue.opacity(0.9) : Color.black.opacity(0.22), lineWidth: 2)
            .frame(width: 22, height: 22)
            .overlay {
                if isSelected {
                    Circle()
                        .fill(Color.blue.opacity(0.9))
                        .frame(width: 12, height: 12)
                }
            }
    }

    func bankAccountSummary(_ account: OrganizationBankAccount, isExpanded: Bool) -> some View {
        let bankName = bankValue(account.id, \.bankName)
        let accountNumber = bankValue(account.id, \.bankAccount)

        return HStack(alignment: .center, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: 4) {
                Text(bankName.isEmpty ? "Банк не указан" : bankName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(1)

                Text("Расчетный счет")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColor.Text.secondary)

                Text(accountNumber.isEmpty ? "Не указан" : String(accountNumber.filter(\.isNumber).prefix(20)))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColor.Text.primary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }

            Spacer(minLength: AppSpacing.xs)

            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppColor.Text.secondary)
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    func bankAccountDetails(_ account: OrganizationBankAccount) -> some View {
        let accountNumber = bankValue(account.id, \.bankAccount)
        let bankCode = bankValue(account.id, \.bankCode)
        let correspondentAccount = bankValue(account.id, \.correspondentAccount)

        VStack(alignment: .leading, spacing: AppSpacing.md) {
            formField("Название банка", value: bankValue(account.id, \.bankName)) {
                viewModel.updateBankAccount(id: account.id, field: .bankName, value: $0)
            }

            formField("Расчетный счет", value: accountNumber) {
                viewModel.updateBankAccount(id: account.id, field: .bankAccount, value: $0)
            }
            .keyboardType(.numberPad)

            validationMessage(accountNumber, requiredCount: 20, title: "Расчетный счет")

            formField("БИК", value: bankCode) {
                viewModel.updateBankAccount(id: account.id, field: .bankCode, value: $0)
            }
            .keyboardType(.numberPad)

            validationMessage(bankCode, requiredCount: 9, title: "БИК")

            formField("Корреспондентский счет", value: correspondentAccount) {
                viewModel.updateBankAccount(id: account.id, field: .correspondentAccount, value: $0)
            }
            .keyboardType(.numberPad)

            validationMessage(correspondentAccount, requiredCount: 20, title: "Корреспондентский счет")

            if viewModel.draft.bankAccounts.count > 1 {
                Button(role: .destructive) {
                    viewModel.removeBankAccount(id: account.id)
                    expandedBankAccountIDs.remove(account.id)
                } label: {
                    Label("Удалить счет", systemImage: "trash")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    func validationMessage(_ value: String, requiredCount: Int, title: String) -> some View {
        if value.isEmpty == false && value.filter(\.isNumber).count != requiredCount {
            Text("\(title) должен содержать \(requiredCount) цифр")
                .font(AppFont.Text.caption)
                .foregroundStyle(.red.opacity(0.78))
        }
    }

    @ViewBuilder
    var actionsCard: some View {
        if viewModel.errorMessage != nil || viewModel.hasUnsavedChanges || viewModel.isNewOrganization == false {
            VStack(spacing: AppSpacing.sm) {
            if let message = viewModel.errorMessage {
                Text(message)
                    .font(AppFont.Text.caption)
                    .foregroundStyle(.white.opacity(0.78))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

                if viewModel.hasUnsavedChanges {
                    Button {
                        Task {
                            await viewModel.save()
                        }
                    } label: {
                        Text(viewModel.saveButtonTitle)
                            .font(AppFont.Control.button)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background {
                                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                    .fill(viewModel.canSave ? AppColor.Brand.primary : .white.opacity(0.18))
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.canSave == false)
                }

                if viewModel.isNewOrganization == false {
                    Button {
                        showsDeleteConfirmation = true
                    } label: {
                        Text("Удалить организацию")
                            .font(AppFont.Control.button)
                            .foregroundStyle(.white.opacity(0.78))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Components

private extension OrganizationProfileSettingsScreen {
    func sectionHeader(
        title: String,
        subtitle: String,
        onDarkBackground: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppFont.Text.headline)
                .foregroundStyle(onDarkBackground ? .white : AppColor.Text.primary)

            Text(subtitle)
                .font(AppFont.Text.caption)
                .foregroundStyle(onDarkBackground ? .white.opacity(0.72) : AppColor.Text.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func formField(
        _ title: String,
        value: String,
        onChange: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Text.secondary)

            TextField(title, text: Binding(get: { value }, set: onChange))
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppColor.Text.primary)
                .padding(.horizontal, AppSpacing.md)
                .frame(height: 46)
                .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var divider: some View {
        Rectangle()
            .fill(Color.black.opacity(0.07))
            .frame(height: 1)
    }

    func bankValue(
        _ id: UUID,
        _ keyPath: KeyPath<OrganizationBankAccount, String>
    ) -> String {
        viewModel.draft.bankAccounts.first { $0.id == id }?[keyPath: keyPath] ?? ""
    }

    func toggleBankAccountDetails(_ id: UUID) {
        if expandedBankAccountIDs.contains(id) {
            expandedBankAccountIDs.remove(id)
        } else {
            expandedBankAccountIDs.insert(id)
        }
    }

}

#Preview {
    OrganizationProfileSettingsScreen(
        viewModel: OrganizationProfileSettingsViewModel(
            organizationsRepository: PreviewOrganizationProfileRepository(),
            organizationSearchService: PreviewOrganizationProfileSearchService()
        )
    )
}

private actor PreviewOrganizationProfileRepository: OrganizationsRepositoryProtocol {
    func fetchOrganizations() async throws -> [Organization] {
        [
            Organization(
                party: DocumentParty(
                    displayName: "ООО Автозаказ",
                    taxID: "7707083893",
                    registrationNumber: "КПП 773601001 / ОГРН 1027700132195",
                    address: "г Москва, ул Вавилова, д 19"
                ),
                role: .seller,
                bankAccounts: [
                    OrganizationBankAccount(
                        bankName: "ПАО Сбербанк",
                        bankAccount: "40702810900000000001",
                        bankCode: "044525225",
                        correspondentAccount: "30101810400000000225",
                        isDefault: true
                    )
                ],
                isDefault: true
            )
        ]
    }

    func save(organization: Organization) async throws { }
    func deleteOrganization(id: UUID) async throws { }
    func upsert(party: DocumentParty, role: Organization.Role) async throws { }
}

private struct PreviewOrganizationProfileSearchService: OrganizationSearchServiceProtocol {
    func searchOrganizations(query: String) async throws -> [OrganizationSuggestion] {
        []
    }
}
