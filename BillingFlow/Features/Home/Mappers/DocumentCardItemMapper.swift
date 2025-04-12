import Foundation

struct DocumentCardItemMapper {

    nonisolated init() { }

    func map(_ document: BusinessDocument) -> DocumentCardItem {
        DocumentCardItem(
            id: document.id,
            iconName: iconName(for: document.type),
            title: documentTitle(for: document),
            subtitle: documentSubtitle(for: document),
            amount: CurrencyFormatter.amountText(
                document.totals.total,
                currencyCode: document.currencyCode
            ),
            statusTitle: "Статус",
            statusAmount: statusText(for: document.status),
            statusStyle: statusStyle(for: document.status)
        )
    }

    private func iconName(for type: DocumentType) -> String {
        switch type {
        case .invoice:
            return "doc.text.fill"
        case .act:
            return "checkmark.seal.fill"
        case .deliveryNote:
            return "doc.text.magnifyingglass"
        }
    }

    private func documentTitle(for document: BusinessDocument) -> String {
        let typeName = document.type.displayName
        let number = document.number.trimmingCharacters(in: .whitespacesAndNewlines)

        guard number.isEmpty == false else {
            return "\(typeName) без номера"
        }

        return "\(typeName) №\(number)"
    }

    private func documentSubtitle(for document: BusinessDocument) -> String {
        let dateText = AppDateFormatter.documentDateText(document.date)
        let buyerName = document.buyer.displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard buyerName.isEmpty == false else {
            return dateText
        }

        return "\(buyerName) • \(dateText)"
    }

    private func statusText(for status: DocumentStatus) -> String {
        switch status {
        case .draft:
            return "Черновик"
        case .ready:
            return "Готов"
        case .shared:
            return "Отправлен"
        }
    }

    private func statusStyle(for status: DocumentStatus) -> StatusPill.Style {
        switch status {
        case .draft:
            return .neutral
        case .ready:
            return .positive
        case .shared:
            return .positive
        }
    }
}
