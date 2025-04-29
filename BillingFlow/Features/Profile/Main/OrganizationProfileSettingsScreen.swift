import SwiftUI

struct OrganizationProfileSettingsScreen: View {

    // MARK: - State

    @StateObject private var viewModel: OrganizationProfileSettingsViewModel
    @State private var showsDeleteConfirmation = false

    // MARK: - Initialization

    init(viewModel: OrganizationProfileSettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ProfileSettingsContainer(
            title: "Профиль организации",
            subtitle: "Свои компании, реквизиты и банковские счета для документов."
        ) {
            VStack(spacing: AppSpacing.lg) {
                organizationsSection
                if viewModel.isSearchVisible {
                    searchSection
                }
                formSection
            }
        }
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

// MARK: - Organizations

private extension OrganizationProfileSettingsScreen {
    var organizationsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(
                title: "Мои организации",
                subtitle: "Выберите, от кого выставлять документы",
                onDarkBackground: true
            )

            if viewModel.isLoading {
                loadingCard
            } else if viewModel.organizations.isEmpty {
                emptyOrganizationsCard
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(viewModel.organizations) { organization in
                            organizationChip(organization)
                        }

                        addOrganizationChip
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
                .scrollIndicators(.hidden)
                .padding(.horizontal, -AppSpacing.md)
            }
        }
    }

    func organizationChip(_ organization: Organization) -> some View {
        let isSelected = organization.id == viewModel.selectedOrganizationID

        return Button {
            viewModel.selectOrganization(organization)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: AppSpacing.sm) {
                    Text(initials(for: organization.party.displayName))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isSelected ? .white : AppColor.Text.primary)
                        .frame(width: 34, height: 34)
                        .background {
                            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                .fill(isSelected ? AppColor.Brand.primary : Color.black.opacity(0.06))
                        }

                    if organization.isDefault {
                        Text("Основная")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(isSelected ? .white.opacity(0.86) : AppColor.Brand.primary)
                            .padding(.horizontal, 8)
                            .frame(height: 24)
                            .background {
                                Capsule()
                                    .fill(isSelected ? .white.opacity(0.18) : AppColor.Brand.primary.opacity(0.12))
                            }
                    }
                }

                Text(organization.party.displayName.isEmpty ? "Без названия" : organization.party.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : AppColor.Text.primary)
                    .lineLimit(2)

                Text(organization.party.taxID.isEmpty ? "ИНН не указан" : "ИНН \(organization.party.taxID)")
                    .font(AppFont.Text.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.72) : AppColor.Text.secondary)
                    .lineLimit(1)
            }
            .frame(width: 188, alignment: .leading)
            .padding(AppSpacing.md)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(isSelected ? AppColor.Brand.primary : .white.opacity(0.92))
            }
        }
        .buttonStyle(.plain)
    }

    var addOrganizationChip: some View {
        Button {
            viewModel.startNewOrganization()
        } label: {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppColor.Brand.primary)
                    .frame(width: 34, height: 34)
                    .background {
                        RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                            .fill(AppColor.Brand.primary.opacity(0.12))
                    }

                Text("Добавить")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColor.Text.primary)

                Text("ИНН, реквизиты, счета")
                    .font(AppFont.Text.caption)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(1)
            }
            .frame(width: 150, alignment: .leading)
            .padding(AppSpacing.md)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(.white.opacity(0.92))
            }
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
                    viewModel.startNewOrganization()
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
                        viewModel.selectSuggestion(suggestion)
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(suggestion.shortName.isEmpty ? suggestion.name : suggestion.shortName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppColor.Text.primary)
                                    .lineLimit(1)

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
            sectionHeader(
                title: viewModel.title,
                subtitle: "Эти данные попадут в документы",
                onDarkBackground: true
            )

            organizationDetailsCard
            bankAccountsCard
            actionsCard
        }
    }

    var organizationDetailsCard: some View {
        MaterialCard(cornerRadius: AppRadius.lg) {
            VStack(spacing: AppSpacing.md) {
                formField("Название", value: viewModel.draft.party.displayName) {
                    viewModel.updatePartyField(.displayName, value: $0)
                }

                HStack(spacing: AppSpacing.sm) {
                    formField("ИНН", value: viewModel.draft.party.taxID) {
                        viewModel.updatePartyField(.taxID, value: $0)
                    }
                    .keyboardType(.numberPad)

                    formField("КПП / ОГРН", value: viewModel.draft.party.registrationNumber) {
                        viewModel.updatePartyField(.registrationNumber, value: $0)
                    }
                }

                formField("Юридический адрес", value: viewModel.draft.party.address) {
                    viewModel.updatePartyField(.address, value: $0)
                }

                formField("Руководитель", value: viewModel.draft.party.contactName) {
                    viewModel.updatePartyField(.contactName, value: $0)
                }

                HStack(spacing: AppSpacing.sm) {
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

                defaultOrganizationControl
            }
        }
    }

    var defaultOrganizationControl: some View {
        Button {
            viewModel.makeCurrentOrganizationDefault()
        } label: {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: viewModel.draft.isDefault ? "checkmark.seal.fill" : "seal")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(viewModel.draft.isDefault ? .white : AppColor.Brand.primary)
                    .frame(width: 40, height: 40)
                    .background {
                        RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                            .fill(viewModel.draft.isDefault ? AppColor.Brand.primary : AppColor.Brand.primary.opacity(0.12))
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.draft.isDefault ? "Основная организация" : "Сделать основной")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColor.Text.primary)

                    Text(viewModel.draft.isDefault ? "Выбрана как основная" : "Использовать эту организацию по умолчанию")
                        .font(AppFont.Text.caption)
                        .foregroundStyle(AppColor.Text.secondary)
                }

                Spacer(minLength: AppSpacing.sm)

                if viewModel.draft.isDefault == false {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppColor.Text.secondary)
                }
            }
            .padding(AppSpacing.md)
            .background(Color.black.opacity(0.04), in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.draft.isDefault)
    }

    var bankAccountsCard: some View {
        MaterialCard(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack(alignment: .center, spacing: AppSpacing.sm) {
                    sectionHeader(
                        title: "Банковские счета",
                        subtitle: "Можно хранить несколько счетов одной компании"
                    )

                    Spacer(minLength: AppSpacing.sm)

                    Button {
                        viewModel.addBankAccount()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background {
                                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                    .fill(AppColor.Brand.primary)
                            }
                    }
                    .buttonStyle(.plain)
                }

                ForEach(viewModel.draft.bankAccounts) { account in
                    bankAccountCard(account)
                }
            }
        }
    }

    func bankAccountCard(_ account: OrganizationBankAccount) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                Button {
                    viewModel.setDefaultBankAccount(id: account.id)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: account.id == viewModel.draft.defaultBankAccountID ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 16, weight: .semibold))

                        Text("Основной счет")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(account.id == viewModel.draft.defaultBankAccountID ? AppColor.Brand.primary : AppColor.Text.secondary)
                }
                .buttonStyle(.plain)

                Spacer(minLength: AppSpacing.sm)

                Button {
                    viewModel.removeBankAccount(id: account.id)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColor.Text.secondary)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.draft.bankAccounts.count == 1)
                .opacity(viewModel.draft.bankAccounts.count == 1 ? 0.35 : 1)
            }

            formField("Банк", value: bankValue(account.id, \.bankName)) {
                viewModel.updateBankAccount(id: account.id, field: .bankName, value: $0)
            }

            HStack(spacing: AppSpacing.sm) {
                formField("Расчетный счет", value: bankValue(account.id, \.bankAccount)) {
                    viewModel.updateBankAccount(id: account.id, field: .bankAccount, value: $0)
                }
                .keyboardType(.numberPad)

                formField("БИК", value: bankValue(account.id, \.bankCode)) {
                    viewModel.updateBankAccount(id: account.id, field: .bankCode, value: $0)
                }
                .keyboardType(.numberPad)
            }

            formField("Корреспондентский счет", value: bankValue(account.id, \.correspondentAccount)) {
                viewModel.updateBankAccount(id: account.id, field: .correspondentAccount, value: $0)
            }
            .keyboardType(.numberPad)
        }
        .padding(AppSpacing.md)
        .background(Color.black.opacity(0.04), in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }

    var actionsCard: some View {
        VStack(spacing: AppSpacing.sm) {
            if let message = viewModel.errorMessage {
                Text(message)
                    .font(AppFont.Text.caption)
                    .foregroundStyle(.white.opacity(0.78))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

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

    func initials(for name: String) -> String {
        let value = name.isEmpty ? "?" : name
        return value
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
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
