import SwiftUI

struct OrganizationsScreen: View {

    // MARK: - State

    @StateObject private var viewModel: OrganizationsViewModel

    // MARK: - Initialization

    init(viewModel: OrganizationsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    headerSection
                    primaryAction
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
            Text("Организации")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)

            Text("Контрагенты, реквизиты и профили компаний")
                .font(AppFont.Text.caption)
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var primaryAction: some View {
        Button {

        } label: {
            Label("Добавить организацию", systemImage: "building.2.crop.circle.fill")
                .font(AppFont.Control.button)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background {
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(AppColor.Brand.primary)
                }
        }
        .buttonStyle(.plain)
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

        } label: {
            HStack(spacing: AppSpacing.md) {
                Text(organization.initials)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background {
                        RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                            .fill(.black.opacity(0.62))
                    }

                VStack(alignment: .leading, spacing: 5) {
                    Text(organization.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColor.Text.primary)
                        .lineLimit(1)

                    Text("\(organization.roleTitle) · \(organization.taxIDText)")
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
            .padding(.leading, 74)
    }

    var emptyState: some View {
        MaterialCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Организаций пока нет")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColor.Text.primary)

                Text("После создания счета продавец и покупатель появятся здесь автоматически.")
                    .font(AppFont.Text.caption)
                    .foregroundStyle(AppColor.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
