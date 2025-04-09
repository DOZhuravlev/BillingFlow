import SwiftUI

struct BillGroupCard: View {
    let iconName: String
    let title: String
    let date: String
    let amount: String
    let statusTitle: String
    let statusAmount: String
    let statusStyle: StatusPill.Style

//    var body: some View {
//        MaterialCard(cornerRadius: AppRadius.lg) {
//            VStack(spacing: AppSpacing.md) {
//                HStack(spacing: AppSpacing.sm) {
//                    Image(systemName: iconName)
//                        .font(.system(size: 20, weight: .semibold))
//                        .frame(width: 44, height: 44)
//                        .background {
//                            Circle()
//                                .fill(.white.opacity(0.35))
//                        }
//
//                    VStack(alignment: .leading, spacing: 2) {
//                        Text(title)
//                            .font(AppFont.Text.headline)
//                            .foregroundStyle(AppColor.Text.primary)
//
//                        Text(date)
//                            .font(AppFont.Text.caption)
//                            .foregroundStyle(AppColor.Text.secondary)
//                    }
//
//                    Spacer()
//
//                    Text(amount)
//                        .font(AppFont.Text.caption)
//                        .foregroundStyle(AppColor.Text.secondary)
//                }
//
//                StatusPill(
//                    title: statusTitle,
//                    amount: statusAmount,
//                    style: statusStyle
//                )
//            }
//        }
//    }

    var body: some View {
        MaterialCard(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                topRow
                documentRow
                //bottomRow
            }
        }
    }

    private var topRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
            Text(title)
                .font(AppFont.Text.headline)
                .foregroundStyle(AppColor.Text.primary)
                .lineLimit(1)

            Spacer(minLength: AppSpacing.sm)

            Text(amount)
                .font(AppFont.Text.headline)
                .foregroundStyle(AppColor.Text.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }

    }

    private var documentRow: some View {

        HStack(spacing: AppSpacing.xs) {

//            Image(systemName: iconName)
//
//                .font(.system(size: 14, weight: .semibold))
//
//                .foregroundStyle(.white)

//            Text(title)
//                .font(AppFont.Text.headline)
//                .foregroundStyle(AppColor.Text.primary)
//                .lineLimit(1)

            Text(date)
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Text.secondary)
                .lineLimit(1)

//            Text(statusTitle)
//
//                .font(AppFont.Text.caption)
//
//                .fontWeight(.semibold)
//
//                .foregroundStyle(AppColor.Text.secondary)
//
//                .lineLimit(1)

            Spacer(minLength: 0)

        }

    }

    private var bottomRow: some View {

        HStack(alignment: .center, spacing: AppSpacing.sm) {

            Text(date)
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Text.secondary)
                .lineLimit(1)

            Spacer(minLength: AppSpacing.sm)

//            StatusPill(
//
//                title: "Status pill",
//
//                amount: statusAmount,
//
//                style: statusStyle
//
//            )

        }

    }
}

#Preview {
    BillGroupCard(iconName: "doc.text.fill", title: "Счет №12", date: "29 апреля 2026г.", amount: "15 300 ₽", statusTitle: "Оплачено", statusAmount: "Не оплачен", statusStyle: .negative)
}
