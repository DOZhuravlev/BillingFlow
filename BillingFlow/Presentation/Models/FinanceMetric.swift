import Foundation

struct FinanceMetric: Identifiable {
    let id = UUID()
    let title: String
    let amount: String
    let style: FinanceMetricStyle
}
