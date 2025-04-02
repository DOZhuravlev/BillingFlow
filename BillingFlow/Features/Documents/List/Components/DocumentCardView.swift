import SwiftUI

struct DocumentCardView: View {

    // MARK: - Input Data

    let document: BusinessDocument

    // MARK: - Formatters

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
            headerRow
            counterpartyBlock
            amountBlock
            dateBlock
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(color: Color.black.opacity(0.05), radius: 18, x: 0, y: 10)
        .contentShape(Rectangle())
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(document.number.isEmpty ? "Без номера" : document.number)
                .font(.headline)

            Spacer()

            Text(document.status.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(statusTint)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(statusTint.opacity(0.12))
                .clipShape(Capsule())
        }
    }

    // MARK: - Counterparty Info

    private var counterpartyBlock: some View {
        Text(counterpartyText)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(2)
    }

    // MARK: - Amount

    private var amountBlock: some View {
        Text(totalAmountText)
            .font(.title3.weight(.semibold))
    }

    // MARK: - Date

    private var dateBlock: some View {
        Text(documentDateText)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    // MARK: - Styling

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(.white)
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(Color.black.opacity(0.04), lineWidth: 1)
    }

    // MARK: - Computed Data

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
        case .draft: return .orange
        case .ready: return .blue
        case .shared: return .green
        }
    }
}
