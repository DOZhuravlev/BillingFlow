import Foundation

protocol FinanceSummaryServiceProtocol {
    func makeSummary(
        documents: [BusinessDocument],
        filter: FinanceSummaryFilter
    ) -> FinanceSummary
}

struct MockFinanceSummaryService: FinanceSummaryServiceProtocol {
    func makeSummary(
        documents: [BusinessDocument],
        filter: FinanceSummaryFilter
    ) -> FinanceSummary {

        // TODO: Replace mock logic with real aggregation by status/date/organization.

        FinanceSummary(
            receivedAmount: 385_738.21,
            pendingAmount: 254_333.43
        )
    }
}
