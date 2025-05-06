import Combine
import Foundation

@MainActor
final class OrganizationDetailViewModel: ObservableObject {

    struct DocumentSection: Identifiable {
        let id: String
        let title: String
        let countText: String
        let documents: [BusinessDocument]
    }

    // MARK: - State

    @Published private(set) var item: OrganizationsViewModel.Item
    @Published var isDetailsExpanded = false

    // MARK: - Dependencies

    private weak var coordinator: DocumentsCoordinatorProtocol?

    // MARK: - Initialization

    init(
        item: OrganizationsViewModel.Item,
        coordinator: DocumentsCoordinatorProtocol
    ) {
        self.item = item
        self.coordinator = coordinator
    }
}

// MARK: - Actions

extension OrganizationDetailViewModel {
    func didTapDocument(_ document: BusinessDocument) {
        coordinator?.showDetail(document: document)
    }
}

// MARK: - Display State

extension OrganizationDetailViewModel {
    var documentSections: [DocumentSection] {
        let calendar = Calendar.current
        let groupedDocuments = Dictionary(grouping: item.documents) { document in
            let components = calendar.dateComponents([.year, .month], from: document.date)
            return DateComponents(year: components.year, month: components.month)
        }

        return groupedDocuments.compactMap { components, documents in
            guard let date = calendar.date(from: components) else { return nil }
            let sortedDocuments = documents.sorted { $0.date > $1.date }

            return DocumentSection(
                id: "\(components.year ?? 0)-\(components.month ?? 0)",
                title: Self.monthTitle(for: date),
                countText: "\(sortedDocuments.count) \(Self.documentWord(for: sortedDocuments.count))",
                documents: sortedDocuments
            )
        }
        .sorted { lhs, rhs in
            guard
                let lhsDate = Self.sectionDate(from: lhs.id),
                let rhsDate = Self.sectionDate(from: rhs.id)
            else {
                return lhs.title > rhs.title
            }

            return lhsDate > rhsDate
        }
    }

    func title(for document: BusinessDocument) -> String {
        let number = document.number.trimmingCharacters(in: .whitespacesAndNewlines)
        guard number.isEmpty == false else {
            return "\(document.type.displayName) без номера"
        }

        return "\(document.type.displayName) №\(number)"
    }

    func subtitle(for document: BusinessDocument) -> String {
        AppDateFormatter.documentDateText(document.date)
    }

    func amountText(for document: BusinessDocument) -> String {
        CurrencyFormatter.amountText(
            document.totals.total,
            currencyCode: document.currencyCode
        )
    }

    private static func monthTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL"

        let title = formatter.string(from: date)
        return title.prefix(1).uppercased() + title.dropFirst()
    }

    private static func sectionDate(from id: String) -> Date? {
        let parts = id.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }

        return Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1]))
    }

    private static func documentWord(for count: Int) -> String {
        let mod10 = count % 10
        let mod100 = count % 100

        if mod10 == 1 && mod100 != 11 {
            return "документ"
        }

        if (2...4).contains(mod10) && !(12...14).contains(mod100) {
            return "документа"
        }

        return "документов"
    }
}
