import Foundation

enum FinanceMetricStyle {
    case income
    case pending
    case debt
    case neutral
}

extension FinanceMetricStyle {
    var iconName: String {
        switch self {
        case .income:
            return "arrow.down.left"
        case .pending:
            return "clock"
        case .debt:
            return "arrow.up.right"
        case .neutral:
            return "chart.bar"
        }
    }
}
