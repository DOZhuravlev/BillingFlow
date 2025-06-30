import SwiftUI

struct NotificationSettingsScreen: View {

    // MARK: - State

    @ObservedObject private var preferences: NotificationPreferences
    private let notificationCoordinator: AppNotificationCoordinator?
    let onBack: () -> Void

    init(
        preferences: NotificationPreferences,
        notificationCoordinator: AppNotificationCoordinator? = nil,
        onBack: @escaping () -> Void = { }
    ) {
        self.preferences = preferences
        self.notificationCoordinator = notificationCoordinator
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
                    isOn: Binding(
                        get: { preferences.isEnabled },
                        set: { isEnabled in
                            Task {
                                if let notificationCoordinator {
                                    await notificationCoordinator.setNotificationsEnabled(isEnabled)
                                } else {
                                    preferences.setEnabled(isEnabled)
                                }
                            }
                        }
                    )
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
    NotificationSettingsScreen(preferences: NotificationPreferences())
}
