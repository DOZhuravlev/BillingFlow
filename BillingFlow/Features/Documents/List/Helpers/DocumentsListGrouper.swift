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
                    documents: documents.sorted { $0.date > $1.date }
                )
            }
            .sorted { lhs, rhs in
                lhs.key.sortValue > rhs.key.sortValue
            }
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
