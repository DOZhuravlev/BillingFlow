import Foundation

struct DocumentsCounterpartyFilterItem: Identifiable, Equatable {
    let id: String
    let name: String

    static func makeItems(from documents: [BusinessDocument]) -> [DocumentsCounterpartyFilterItem] {
        let names = Set(
            documents
                .map { $0.buyer.displayName }
                .filter { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
        )

        return names
            .map {
                DocumentsCounterpartyFilterItem(
                    id: $0,
                    name: $0
                )
            }
            .sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }
}
