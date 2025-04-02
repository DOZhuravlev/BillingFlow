import SwiftUI

struct BillGroupCard: View {
    let iconName: String
    let title: String
    let date: String
    let amount: String
    let statusTitle: String
    let statusAmount: String
    let statusStyle: StatusPill.Style

    var body: some View {
        MaterialCard(cornerRadius: AppRadius.lg) {
            VStack(spacing: AppSpacing.md) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .background {
                            Circle()
                                .fill(.white.opacity(0.35))
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(AppFont.Text.headline)
                            .foregroundStyle(AppColor.Text.primary)

                        Text(date)
                            .font(AppFont.Text.caption)
                            .foregroundStyle(AppColor.Text.secondary)
                    }

                    Spacer()

                    Text(amount)
                        .font(AppFont.Text.caption)
                        .foregroundStyle(AppColor.Text.secondary)
                }

                StatusPill(
                    title: statusTitle,
                    amount: statusAmount,
                    style: statusStyle
                )
            }
        }
    }
}

#Preview {
    BillGroupCard(iconName: "doc.text.fill", title: "Счет №12", date: "29 апреля 2026г.", amount: "15 300 ₽", statusTitle: "Оплачено", statusAmount: "Не оплачен", statusStyle: .negative)
}
