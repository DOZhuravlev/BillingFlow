import SwiftUI

struct ProfileScreen: View {

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    headerSection
                    organizationSection
                    documentsSection
                    appSection
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
        VStack(alignment: .leading, spacing: AppSpacing.md) {
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
            }
        }
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

    var organizationSection: some View {
        settingsSection(title: "Организация") {
            settingsRow(
                title: "Профиль организации",
                subtitle: "Название, ИНН, КПП и контакты",
                iconName: "building.2.fill"
            )

            divider

            settingsRow(
                title: "Банковские реквизиты",
                subtitle: "Счёт, БИК, банк и корреспондентский счёт",
                iconName: "building.columns.fill"
            )

            divider

            settingsRow(
                title: "Адрес и представители",
                subtitle: "Юридический адрес и руководитель",
                iconName: "person.text.rectangle.fill"
            )
        }
    }

    var documentsSection: some View {
        settingsSection(title: "Документы") {
            settingsRow(
                title: "Подпись и печать",
                subtitle: "Загрузите подпись, печать и настройте отображение",
                iconName: "signature"
            )

            divider

            settingsRow(
                title: "Шаблоны документов",
                subtitle: "Счета, акты и счета-фактуры",
                iconName: "doc.on.doc.fill"
            )

            divider

            settingsRow(
                title: "Нумерация",
                subtitle: "Префиксы и следующий номер документа",
                iconName: "number.square.fill"
            )
        }
    }

    var appSection: some View {
        settingsSection(title: "Приложение") {
            settingsRow(
                title: "Экспорт и хранение",
                subtitle: "PDF, папка документов и резервные копии",
                iconName: "square.and.arrow.up.fill"
            )

            divider

            settingsRow(
                title: "Уведомления",
                subtitle: "Напоминания об оплате и сроках",
                iconName: "bell.fill"
            )

            divider

            settingsRow(
                title: "Поддержка",
                subtitle: "Помощь, обратная связь и версия приложения",
                iconName: "questionmark.circle.fill"
            )
        }
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
        iconName: String
    ) -> some View {
        Button {

        } label: {
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
}

#Preview {
    ProfileScreen()
}
