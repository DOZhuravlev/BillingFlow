import SwiftUI

struct ProfileScreen: View {

    // MARK: - Actions

    let onOrganizationProfile: () -> Void
    let onSignatureAndStamp: () -> Void
    let onNotifications: () -> Void

    // MARK: - Initialization

    init(
        onOrganizationProfile: @escaping () -> Void = { },
        onSignatureAndStamp: @escaping () -> Void = { },
        onNotifications: @escaping () -> Void = { }
    ) {
        self.onOrganizationProfile = onOrganizationProfile
        self.onSignatureAndStamp = onSignatureAndStamp
        self.onNotifications = onNotifications
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    headerSection
                    settingsListSection
                    versionSection
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppLayout.floatingTabBarBottomInset)
            }
            .scrollIndicators(.hidden)
        }
    }
}

// MARK: - Layout

private extension ProfileScreen {

    var backgroundLayer: some View {
        AppColor.Brand.background
            .ignoresSafeArea()
    }
}

// MARK: - Header

private extension ProfileScreen {

    var headerSection: some View {
        Button(action: onOrganizationProfile) {
            HStack(alignment: .center, spacing: AppSpacing.md) {
                organizationAvatar

                VStack(alignment: .leading, spacing: 6) {
                    Text("ООО Автозаказ")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text("Профиль, реквизиты и оформление документов")
                        .font(AppFont.Text.caption)
                        .foregroundStyle(.white.opacity(0.72))
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var organizationAvatar: some View {
        Text("АЗ")
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 56, height: 56)
            .background {
                Circle()
                    .fill(.white.opacity(0.18))
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.34), lineWidth: 1)
                    }
            }
    }
}

// MARK: - Sections

private extension ProfileScreen {

    var settingsListSection: some View {
        settingsSection(title: "Настройки") {
            settingsRow(
                title: "Подпись и печать",
                subtitle: "Загрузите подпись, печать и настройте отображение",
                iconName: "signature",
                action: onSignatureAndStamp
            )

            divider

            settingsRow(
                title: "Уведомления",
                subtitle: "Напоминания об оплате и сроках",
                iconName: "bell.fill",
                action: onNotifications
            )
        }
    }

    var versionSection: some View {
        VStack(spacing: 4) {
            Text("Версия \(appVersion) (\(buildNumber))")
                .font(AppFont.Text.caption)
                .foregroundStyle(.white.opacity(0.62))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.sm)
    }
}

// MARK: - Components

private extension ProfileScreen {

    func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(title)
                .font(AppFont.Text.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, AppSpacing.md)

            MaterialCard(cornerRadius: AppRadius.lg, padding: 0) {
                VStack(spacing: 0) {
                    content()
                }
            }
        }
    }

    func settingsRow(
        title: String,
        subtitle: String,
        iconName: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: iconName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppColor.Text.primary)
                    .frame(width: 38, height: 38)
                    .background {
                        RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                            .fill(.white.opacity(0.46))
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColor.Text.primary)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(AppFont.Text.caption)
                        .foregroundStyle(AppColor.Text.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: AppSpacing.sm)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppColor.Text.secondary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.34))
            .frame(height: 1)
            .padding(.leading, 68)
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

#Preview {
    ProfileScreen()
}
