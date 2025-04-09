import Foundation

struct DocumentsFilter: Equatable {
    var counterpartyName: String?
    var type: DocumentTypeFilter = .all
    var status: DocumentStatusFilter = .all
    var period: DocumentsPeriodFilter = .all

    var hasActiveFilters: Bool {
        counterpartyName != nil ||
        type != .all ||
        status != .all ||
        period != .all
    }

    var hasAdvancedFilters: Bool {
        type != .all ||
        status != .all ||
        period != .all
    }

    var activeChips: [DocumentsFilterChipItem] {
        var chips: [DocumentsFilterChipItem] = []

        if type != .all {
            chips.append(
                DocumentsFilterChipItem(
                    title: type.title,
                    kind: .type
                )
            )
        }

        if status != .all {
            chips.append(
                DocumentsFilterChipItem(
                    title: status.title,
                    kind: .status
                )
            )
        }

        if period != .all {
            chips.append(
                DocumentsFilterChipItem(
                    title: period.title,
                    kind: .period
                )
            )
        }

        return chips
    }

    func matches(_ document: BusinessDocument) -> Bool {
        matchesCounterparty(document) &&
        type.matches(document) &&
        status.matches(document) &&
        period.matches(document.date)
    }

    mutating func resetAdvancedFilters() {
        type = .all
        status = .all
        period = .all
    }

    mutating func resetAll() {
        counterpartyName = nil
        resetAdvancedFilters()
    }

    private func matchesCounterparty(_ document: BusinessDocument) -> Bool {
        guard let counterpartyName else {
            return true
        }

        return document.buyer.displayName == counterpartyName
    }
}
