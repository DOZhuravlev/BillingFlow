import Foundation

struct FinanceSummaryFilter {
    let organizationID: UUID?
    let dateRange: ClosedRange<Date>?
    
    static let all = FinanceSummaryFilter(
        organizationID: nil,
        dateRange: nil
    )
}
