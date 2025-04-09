import Foundation

struct DocumentsListSection: Identifiable {
    let key: DocumentsMonthKey
    let title: String
    let items: [DocumentsListSectionItem]

    var id: Int {
        key.sortValue
    }

    var countText: String {
        "\(items.count) \(items.count.documentCountWord)"
    }
}

struct DocumentsListSectionItem: Identifiable {
    let document: BusinessDocument
    let item: DocumentsListItem

    var id: UUID {
        document.id
    }
}

private extension Int {
    var documentCountWord: String {
        let lastTwoDigits = self % 100
        let lastDigit = self % 10

        if (11...14).contains(lastTwoDigits) {
            return "документов"
        }

        switch lastDigit {
        case 1:
            return "документ"
        case 2...4:
            return "документа"
        default:
            return "документов"
        }
    }
}
