import SwiftUI

struct StatusPill: View {

    // MARK: - Properties

    let title: String
    let amount: String
    let style: Style

    // MARK: - Style

    enum Style {
        case positive
        case negative
        case neutral
    }

    // MARK: - Body

    var body: some View {
        HStack {
            Text(title)
                .font(AppFont.Text.caption)

            Spacer()

            Text(amount)
                .font(AppFont.Text.caption.bold())
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background {
            Capsule()
                .fill(backgroundColor)
        }
    }

    // MARK: - Private Properties

    private var backgroundColor: Color {
        switch style {
        case .positive:
            AppColor.Status.successBackground.opacity(0.9)
        case .negative:
            AppColor.Status.dangerBackground.opacity(0.9)
        case .neutral:
            Color.white.opacity(0.35)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .positive:
            AppColor.Status.success
        case .negative:
            AppColor.Status.danger
        case .neutral:
                .white
        }
    }
}

#Preview {
    StatusPill(title: "Оплата", amount: "2000", style: .positive)
}
