import Foundation

struct DocumentsListGrouper {
    func groupByMonth(_ documents: [BusinessDocument]) -> [DocumentsMonthSection] {
        let calendar = Calendar.current

        let groups = Dictionary(grouping: documents) { document in
            let components = calendar.dateComponents([.year, .month], from: document.date)

            return DocumentsMonthKey(
                year: components.year ?? 0,
                month: components.month ?? 0
            )
        }

        return groups
            .map { key, documents in
                DocumentsMonthSection(
                    key: key,
                    title: monthTitle(for: key),
                    documents: documents.sorted(by: documentComesBefore)
                )
            }
            .sorted { lhs, rhs in
                let lhsHasDraft = lhs.documents.contains { $0.status == .draft }
                let rhsHasDraft = rhs.documents.contains { $0.status == .draft }
                if lhsHasDraft != rhsHasDraft {
                    return lhsHasDraft
                }
                return lhs.key.sortValue > rhs.key.sortValue
            }
    }

    private func documentComesBefore(_ lhs: BusinessDocument, _ rhs: BusinessDocument) -> Bool {
        if lhs.status == .draft, rhs.status != .draft { return true }
        if lhs.status != .draft, rhs.status == .draft { return false }
        return (lhs.updatedAt ?? lhs.date) > (rhs.updatedAt ?? rhs.date)
    }

    private func monthTitle(for key: DocumentsMonthKey) -> String {
        var components = DateComponents()
        components.year = key.year
        components.month = key.month
        components.day = 1

        guard let date = Calendar.current.date(from: components) else {
            return "Без даты"
        }

        return AppDateFormatter.monthYearText(date)
    }
}
