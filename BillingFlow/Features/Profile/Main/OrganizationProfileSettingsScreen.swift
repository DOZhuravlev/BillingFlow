import SwiftUI

struct OrganizationProfileSettingsScreen: View {

    // MARK: - Body

    var body: some View {
        ProfileSettingsContainer(
            title: "Профиль организации",
            subtitle: "Основные данные, которые будут попадать в документы."
        ) {
            MaterialCard(cornerRadius: AppRadius.lg) {
                VStack(spacing: AppSpacing.md) {
                    settingsField(title: "Название", value: "ООО Автозаказ")
                    settingsField(title: "ИНН", value: "Не указан")
                    settingsField(title: "КПП / ОГРН", value: "Не указан")
                    settingsField(title: "Юридический адрес", value: "Не указан")
                    settingsField(title: "Руководитель", value: "Не указан")
                }
            }

            MaterialCard(cornerRadius: AppRadius.lg) {
                VStack(spacing: AppSpacing.md) {
                    sectionTitle("Банковские реквизиты")
                    settingsField(title: "Банк", value: "Не указан")
                    settingsField(title: "Расчетный счет", value: "Не указан")
                    settingsField(title: "БИК", value: "Не указан")
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(AppFont.Text.headline)
            .foregroundStyle(AppColor.Text.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func settingsField(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Text.secondary)

            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColor.Text.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.md)
                .frame(height: 46)
                .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
        }
    }
}

#Preview {
    OrganizationProfileSettingsScreen()
}
