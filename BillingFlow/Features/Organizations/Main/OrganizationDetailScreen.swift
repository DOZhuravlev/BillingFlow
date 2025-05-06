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
            AppColor.Brand.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    headerCard
                    detailsCard
                    documentsCard
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppLayout.floatingTabBarBottomInset)
            }
            .scrollIndicators(.hidden)
        }
    }
}

// MARK: - Sections

private extension OrganizationDetailScreen {
    var headerCard: some View {
        MaterialCard(cornerRadius: AppRadius.lg) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                Text(viewModel.item.initials)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background {
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .fill(.black.opacity(0.72))
                    }

                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.item.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(AppColor.Text.primary)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(viewModel.item.taxIDText)
                        .font(AppFont.Text.caption)
                        .foregroundStyle(AppColor.Text.secondary)
                }

                Spacer(minLength: 0)
            }
        }
    }

    var detailsCard: some View {
        MaterialCard(cornerRadius: AppRadius.lg, padding: 0) {
            VStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.isDetailsExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppColor.Brand.primary)
                            .frame(width: 42, height: 42)
                            .background(AppColor.Brand.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Реквизиты")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppColor.Text.primary)

                            Text(viewModel.isDetailsExpanded ? "Скрыть данные контрагента" : "Показать ИНН, адрес и контакты")
                                .font(AppFont.Text.caption)
                                .foregroundStyle(AppColor.Text.secondary)
                        }

                        Spacer(minLength: 0)

                        Image(systemName: viewModel.isDetailsExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppColor.Text.secondary)
                    }
                    .padding(AppSpacing.md)
                }
                .buttonStyle(.plain)

                if viewModel.isDetailsExpanded {
                    divider
                    detailRow(title: "Название", value: viewModel.item.party.displayName)
                    divider
                    detailRow(title: "ИНН", value: viewModel.item.party.taxID)
                    divider
                    detailRow(title: "КПП / ОГРН", value: viewModel.item.party.registrationNumber)
                    divider
                    detailRow(title: "Адрес", value: viewModel.item.party.address)
                    divider
                    detailRow(title: "Руководитель", value: viewModel.item.party.contactName)
                    divider
                    detailRow(title: "Email", value: viewModel.item.party.email)
                    divider
                    detailRow(title: "Телефон", value: viewModel.item.party.phone)
                }
            }
        }
    }

    var documentsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Документы")
                .font(AppFont.Text.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, AppSpacing.md)

            ForEach(viewModel.documentSections) { section in
                documentSection(section)
            }
        }
    }
}

// MARK: - Components

private extension OrganizationDetailScreen {
    func detailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Text.secondary)

            Text(value.isEmpty ? "Не указано" : value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(value.isEmpty ? AppColor.Text.secondary : AppColor.Text.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
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
