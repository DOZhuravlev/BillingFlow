import SwiftUI

struct BalanceSummaryCard: View {

    // MARK: - Properties

    let metric: FinanceMetric

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(metric.amount)
                .font(AppFont.Number.amount)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: AppSpacing.sm)

            HStack(alignment: .bottom, spacing: AppSpacing.sm) {
                Text(metric.title)
                    .font(AppFont.Text.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)

                Spacer(minLength: AppSpacing.sm)

                Image(systemName: metric.style.iconName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white.opacity(0.34))
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, minHeight: 108)
        .background(cardBackground)
    }

    // MARK: - Components

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
            .fill(.black.opacity(0.60))
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            }
    }
}

#Preview {
    BalanceSummaryCard(metric: FinanceMetric(title: "Выручка", amount: " 1000 р", style: .debt))
}
