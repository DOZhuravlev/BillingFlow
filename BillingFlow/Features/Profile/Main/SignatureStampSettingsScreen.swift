import SwiftUI

struct SignatureStampSettingsScreen: View {

    let onBack: () -> Void

    init(onBack: @escaping () -> Void = { }) {
        self.onBack = onBack
    }

    // MARK: - Body

    var body: some View {
        ProfileSettingsContainer(
            title: "Подпись и печать",
            subtitle: "Добавьте изображения для документов. Позже они будут попадать в PDF.",
            onBack: onBack
        ) {
            uploadCard(
                title: "Подпись",
                subtitle: "PNG или JPG с прозрачным фоном",
                iconName: "signature"
            )

            uploadCard(
                title: "Печать",
                subtitle: "Круглая печать организации",
                iconName: "seal.fill"
            )
        }
    }

    private func uploadCard(
        title: String,
        subtitle: String,
        iconName: String
    ) -> some View {
        MaterialCard(cornerRadius: AppRadius.lg) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: iconName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppColor.Brand.primary)
                    .frame(width: 48, height: 48)
                    .background(AppColor.Brand.primary.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColor.Text.primary)

                    Text(subtitle)
                        .font(AppFont.Text.caption)
                        .foregroundStyle(AppColor.Text.secondary)
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppColor.Brand.primary)
            }
        }
    }
}

#Preview {
    SignatureStampSettingsScreen()
}
