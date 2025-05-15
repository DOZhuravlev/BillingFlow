import SwiftUI

struct OrganizationDetailScreen: View {

    // MARK: - State

    @StateObject private var viewModel: OrganizationDetailViewModel

    // MARK: - Initialization

    init(viewModel: OrganizationDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                navigationHeader
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, AppSpacing.md)
                    .zIndex(1)

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        summarySection
                        quickActionsSection
                        documentsCard
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppLayout.floatingTabBarBottomInset)
                }
                .scrollIndicators(.hidden)
            }
        }
        .sheet(isPresented: $viewModel.isRequisitesPresented) {
            requisitesSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Layout

private extension OrganizationDetailScreen {
    var backgroundLayer: some View {
        AppColor.Brand.background
            .ignoresSafeArea()
    }
}

// MARK: - Header

private extension OrganizationDetailScreen {
    var navigationHeader: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Button(action: viewModel.didTapBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.16), in: Circle())
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.24), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 5) {
                Text(viewModel.item.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(viewModel.item.taxIDText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(1)
            }
            .padding(.top, 1)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}

// MARK: - Sections

private extension OrganizationDetailScreen {
    var summarySection: some View {
        HStack(spacing: AppSpacing.md) {
            ForEach(viewModel.financeMetrics) { metric in
                BalanceSummaryCard(metric: metric)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
    }

    var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Быстрые действия")
                .font(AppFont.Text.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, AppSpacing.sm)

            HStack(spacing: 8) {
                quickActionButton(title: "Создать счет", iconName: "doc.text.fill") {
                    viewModel.didTapCreateDocument(type: .invoice)
                }

                quickActionButton(title: "Создать акт", iconName: "checkmark.seal.fill") {
                    viewModel.didTapCreateDocument(type: .act)
                }

                quickActionButton(title: "Создать фактуру", iconName: "doc.text.magnifyingglass") {
                    viewModel.didTapCreateDocument(type: .deliveryNote)
                }

                quickActionButton(title: "Реквизиты", iconName: "info.circle.fill") {
                    viewModel.isRequisitesPresented = true
                }
            }
        }
    }

    var requisitesSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Данные организации")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.black.opacity(0.9))

                    VStack(spacing: 10) {
                        requisiteRow(title: "Название", value: viewModel.item.party.displayName)
                        requisiteRow(title: "Полное наименование", value: viewModel.item.party.fullName)
                        requisiteRow(title: "ИНН", value: viewModel.item.party.taxID)
                        requisiteRow(title: "КПП / ОГРН", value: viewModel.item.party.registrationNumber)
                        requisiteRow(title: "Адрес", value: viewModel.item.party.address)
                        requisiteRow(title: "Руководитель", value: viewModel.item.party.contactName)
                        requisiteRow(title: "Email", value: viewModel.item.party.email)
                        requisiteRow(title: "Телефон", value: viewModel.item.party.phone)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Реквизиты")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                requisitesBottomAction
            }
        }
    }

    var documentsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            ForEach(viewModel.documentSections) { section in
                documentSection(section)
            }
        }
    }
}

// MARK: - Components

private extension OrganizationDetailScreen {
    func quickActionButton(
        title: String,
        iconName: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: iconName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppColor.Text.primary)
                    .frame(height: 20)

                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColor.Text.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(.white.opacity(0.86))
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .stroke(.white.opacity(0.22), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    func requisiteRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.black.opacity(0.52))

            Text(value.isEmpty ? "Не указано" : value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(value.isEmpty ? .black.opacity(0.38) : .black.opacity(0.82))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.black.opacity(0.035))
        }
    }

    var requisitesBottomAction: some View {
        Button {
            viewModel.isRequisitesPresented = false
        } label: {
            Text("Готово")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppColor.Brand.primary)
                }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }

    func documentRow(_ document: BusinessDocument) -> some View {
        Button {
            viewModel.didTapDocument(document)
        } label: {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                Image(systemName: iconName(for: document.type))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColor.Brand.primary)
                    .frame(width: 40, height: 40)
                    .background(AppColor.Brand.primary.opacity(0.10), in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text(viewModel.title(for: document))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColor.Text.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(viewModel.subtitle(for: document))
                        .font(AppFont.Text.caption)
                        .foregroundStyle(AppColor.Text.secondary)
                }

                Spacer(minLength: AppSpacing.sm)

                VStack(alignment: .trailing, spacing: 5) {
                    Text(viewModel.amountText(for: document))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColor.Text.primary)
                        .lineLimit(1)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppColor.Text.secondary)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
        }
        .buttonStyle(.plain)
    }

    func documentSection(_ section: OrganizationDetailViewModel.DocumentSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(section.title)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(.white.opacity(0.92))

                Spacer(minLength: AppSpacing.sm)

                Text(section.countText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .padding(.horizontal, AppSpacing.md)

            MaterialCard(cornerRadius: AppRadius.lg, padding: 0) {
                VStack(spacing: 0) {
                    ForEach(section.documents) { document in
                        documentRow(document)

                        if document.id != section.documents.last?.id {
                            divider
                                .padding(.leading, 64)
                        }
                    }
                }
            }
        }
    }

    func iconName(for type: DocumentType) -> String {
        switch type {
        case .invoice:
            return "doc.text.fill"

        case .act:
            return "checkmark.seal.fill"

        case .deliveryNote:
            return "doc.text.magnifyingglass"
        }
    }

    var divider: some View {
        Rectangle()
            .fill(Color.black.opacity(0.07))
            .frame(height: 1)
            .padding(.leading, AppSpacing.md)
    }
}
