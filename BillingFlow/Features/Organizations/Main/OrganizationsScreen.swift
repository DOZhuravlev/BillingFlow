import SwiftUI

struct OrganizationsScreen: View {

    // MARK: - State

    @StateObject private var viewModel: OrganizationsViewModel
    private let onSelect: (OrganizationsViewModel.Item) -> Void

    // MARK: - Initialization

    init(
        viewModel: OrganizationsViewModel,
        onSelect: @escaping (OrganizationsViewModel.Item) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSelect = onSelect
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    headerSection
                    organizationsSection
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppLayout.floatingTabBarBottomInset)
            }
            .scrollIndicators(.hidden)
        }
        .task {
            await viewModel.load()
        }
    }
}

// MARK: - Layout

private extension OrganizationsScreen {

    var backgroundLayer: some View {
        AppColor.Brand.background
            .ignoresSafeArea()
    }
}

// MARK: - Header

private extension OrganizationsScreen {

    var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Контрагенты")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)

            Text("Покупатели, заказчики и компании для быстрых документов")
                .font(AppFont.Text.caption)
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Organizations

private extension OrganizationsScreen {

    var organizationsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Список")
                .font(AppFont.Text.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, AppSpacing.md)

            if viewModel.items.isEmpty {
                emptyState
            } else {
                MaterialCard(cornerRadius: AppRadius.lg, padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(viewModel.items) { organization in
                            organizationRow(organization)

                            if organization.id != viewModel.items.last?.id {
                                divider
                            }
                        }
                    }
                }
            }
        }
    }

    func organizationRow(_ organization: OrganizationsViewModel.Item) -> some View {
        Button {
            onSelect(organization)
        } label: {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(organization.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColor.Text.primary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(organization.taxIDText)
                        .font(AppFont.Text.caption)
                        .foregroundStyle(AppColor.Text.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: AppSpacing.sm)

                VStack(alignment: .trailing, spacing: 5) {
                    Text(organization.documentsCountText)
                        .font(AppFont.Text.caption)
                        .foregroundStyle(AppColor.Text.secondary)
                        .lineLimit(1)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppColor.Text.secondary)
                }
                .padding(.top, 3)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
        }
        .buttonStyle(.plain)
    }

    var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.34))
            .frame(height: 1)
            .padding(.leading, AppSpacing.md)
    }

    var emptyState: some View {
        MaterialCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Контрагентов пока нет")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColor.Text.primary)

                Text("После создания документа покупатели и заказчики появятся здесь автоматически.")
                    .font(AppFont.Text.caption)
                    .foregroundStyle(AppColor.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
