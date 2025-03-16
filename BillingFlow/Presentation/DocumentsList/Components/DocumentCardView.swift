import SwiftUI

struct DocumentCardView: View {

    // MARK: - Properties

    let document: BusinessDocument

    private static let amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.groupingSeparator = " "
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }()

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Text(document.number.isEmpty ? "Без номера" : document.number)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Text(document.status.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusTint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusTint.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text(counterpartyText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Text(totalAmountText)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            Text(documentDateText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 18, x: 0, y: 10)
        .contentShape(Rectangle())
    }

    // MARK: - Components

    private var totalAmountText: String {
        let number = NSDecimalNumber(decimal: document.totals.total)
        let formattedAmount = Self.amountFormatter.string(from: number) ?? number.stringValue
        return "\(formattedAmount) \(document.currencyCode)"
    }

    private var counterpartyText: String {
        let seller = document.seller.displayName.isEmpty ? "Продавец не указан" : document.seller.displayName
        let buyer = document.buyer.displayName.isEmpty ? "Покупатель не указан" : document.buyer.displayName
        return "\(seller) → \(buyer)"
    }

    private var documentDateText: String {
        Self.dateFormatter.string(from: document.date)
    }

    private var statusTint: Color {
        switch document.status {
        case .draft:
            return .orange
        case .ready:
            return .blue
        case .shared:
            return .green
        }
    }
}
