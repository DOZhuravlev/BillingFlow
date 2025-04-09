import Foundation

struct DocumentsMonthSection: Identifiable {
    let key: DocumentsMonthKey
    let title: String
    let documents: [BusinessDocument]

    var id: Int {
        key.sortValue
    }

    var countText: String {
        "\(documents.count) \(documents.count.documentCountWord)"
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
