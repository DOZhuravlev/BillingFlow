import Foundation

enum CurrencyFormatter {

    static func rubleText(_ amount: Decimal) -> String {
        "\(decimalText(amount)) ₽"
    }

    static func amountText(
        _ amount: Decimal,
        currencyCode: String
    ) -> String {
        "\(decimalText(amount)) \(currencyCode)"
    }

    private static func decimalText(_ amount: Decimal) -> String {
        let number = NSDecimalNumber(decimal: amount)
        return formatter.string(from: number) ?? number.stringValue
    }

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.groupingSeparator = " "
        return formatter
    }()
}
