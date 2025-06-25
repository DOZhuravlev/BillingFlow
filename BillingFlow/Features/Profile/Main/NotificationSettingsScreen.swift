import SwiftUI

struct NotificationSettingsScreen: View {

    // MARK: - State

    @State private var notificationsEnabled = true
    let onBack: () -> Void

    init(onBack: @escaping () -> Void = { }) {
        self.onBack = onBack
    }

    // MARK: - Body

    var body: some View {
        ProfileSettingsContainer(
            title: "Уведомления",
            subtitle: "Включите или выключите уведомления приложения.",
            onBack: onBack
        ) {
            MaterialCard(cornerRadius: AppRadius.lg, padding: 0) {
                toggleRow(
                    title: "Уведомления",
                    subtitle: "События по документам, срокам и настройкам",
                    iconName: "bell.fill",
                    isOn: $notificationsEnabled
                )
            }
        }
    }

    private func toggleRow(
        title: String,
        subtitle: String,
        iconName: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: iconName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColor.Text.primary)
                .frame(width: 38, height: 38)
                .background(.white.opacity(0.46), in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColor.Text.primary)

                Text(subtitle)
                    .font(AppFont.Text.caption)
                    .foregroundStyle(AppColor.Text.secondary)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }

}

#Preview {
    NotificationSettingsScreen()
}
