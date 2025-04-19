import SwiftUI

struct NotificationsScreen: View {

    // MARK: - State

    @StateObject private var viewModel: NotificationsViewModel

    // MARK: - Initialization

    init(viewModel: NotificationsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColor.Brand.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    header

                    if viewModel.notifications.isEmpty {
                        emptyState
                    } else {
                        notificationsList
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppLayout.floatingTabBarBottomInset)
            }
            .scrollIndicators(.hidden)
        }
    }
}

// MARK: - Header

private extension NotificationsScreen {
    var header: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Button {
                viewModel.didTapClose()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text("Уведомления")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)

                Text(viewModel.subtitle)
                    .font(AppFont.Text.caption)
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Content

private extension NotificationsScreen {
    var notificationsList: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(viewModel.notifications) { notification in
                notificationRow(notification)
            }
        }
    }

    func notificationRow(_ notification: NotificationItem) -> some View {
        MaterialCard(cornerRadius: AppRadius.lg) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: notification.kind.iconName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppColor.Brand.primary)
                        .frame(width: 42, height: 42)
                        .background(AppColor.Brand.primary.opacity(0.12), in: Circle())

                    if notification.isRead == false {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 9, height: 9)
                            .overlay {
                                Circle()
                                    .stroke(Color.white, lineWidth: 1.5)
                            }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                        Text(notification.title)
                            .font(.system(size: 16, weight: notification.isRead ? .semibold : .bold))
                            .foregroundStyle(AppColor.Text.primary)
                            .lineLimit(2)

                        Spacer()

                        Text(relativeDateText(notification.date))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppColor.Text.secondary)
                            .lineLimit(1)
                    }

                    Text(notification.message)
                        .font(AppFont.Text.caption)
                        .foregroundStyle(AppColor.Text.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    var emptyState: some View {
        MaterialCard {
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(AppColor.Brand.primary)

                Text("Пока тихо")
                    .font(AppFont.Text.headline)
                    .foregroundStyle(AppColor.Text.primary)

                Text("Здесь появятся события по документам, отправкам и настройкам.")
                    .font(AppFont.Text.caption)
                    .foregroundStyle(AppColor.Text.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Formatting

private extension NotificationsScreen {
    func relativeDateText(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NotificationsScreen(viewModel: NotificationsViewModel())
}
