import Foundation
import SwiftUI

struct DocumentsListItemMapper {

    func map(_ document: BusinessDocument) -> DocumentsListItem {
        DocumentsListItem(
            id: document.id,
            iconName: iconName(for: document.type),
            iconStyle: iconStyle(for: document.type),
            title: title(for: document),
            counterpartyName: counterpartyName(for: document),
            dateText: AppDateFormatter.documentDateText(document.date),
            amountText: CurrencyFormatter.amountText(
                document.totals.total,
                currencyCode: document.currencyCode
            ),
            statusText: statusText(for: document.status),
            statusStyle: statusStyle(for: document.status),
            footerText: footerText(for: document),
            primaryActionTitle: primaryActionTitle(for: document),
            secondaryActionTitle: secondaryActionTitle(for: document)
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

    private func iconStyle(for type: DocumentType) -> DocumentsListItem.IconStyle {
        switch type {
        case .invoice:
            return .orange

        case .act:
            return .green

        case .deliveryNote:
            return .purple
        }
    }

    private func title(for document: BusinessDocument) -> String {
        let typeName = document.type.displayName
        let number = document.number.trimmingCharacters(in: .whitespacesAndNewlines)

        guard number.isEmpty == false else {
            return "\(typeName) без номера"
        }

        return "\(typeName) №\(number)"
    }

    private func counterpartyName(for document: BusinessDocument) -> String {
        let buyerName = document.buyer.displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard buyerName.isEmpty == false else {
            return "Контрагент не указан"
        }

        return buyerName
    }

    private func statusText(for status: DocumentStatus) -> String {
        switch status {
        case .draft:
            return "Черновик"

        case .ready:
            return "Готов к отправке"

        case .shared:
            return "Отправлен"
        }
    }

    private func statusStyle(for status: DocumentStatus) -> DocumentsListItem.StatusStyle {
        switch status {
        case .draft:
            return .neutral

        case .ready:
            return .positive

        case .shared:
            return .warning
        }
    }

    private func footerText(for document: BusinessDocument) -> String {
        switch document.status {
        case .draft:
            return draftFooterText(for: document.type)

        case .ready:
            return readyFooterText(for: document.type)

        case .shared:
            return sharedFooterText(for: document.type)
        }
    }

    private func primaryActionTitle(for document: BusinessDocument) -> String? {
        switch document.status {
        case .draft:
            return "Продолжить"

        case .ready:
            return "Отправить"

        case .shared:
            switch document.type {
            case .invoice:
                return "Создать акт"

            case .act, .deliveryNote:
                return "PDF"
            }
        }
    }

    private func secondaryActionTitle(for document: BusinessDocument) -> String? {
        switch document.status {
        case .draft:
            return nil

        case .ready:
            return "PDF"

        case .shared:
            return "Отправить"
        }
    }

    private func draftFooterText(for type: DocumentType) -> String {
        switch type {
        case .invoice:
            return "Заполните данные счёта"

        case .act:
            return "Заполните выполненные работы"

        case .deliveryNote:
            return "Заполните товары, услуги и реквизиты"
        }
    }

    private func readyFooterText(for type: DocumentType) -> String {
        switch type {
        case .invoice:
            return "Документ готов к отправке клиенту"

        case .act:
            return "Акт готов к отправке"

        case .deliveryNote:
            return "Счёт-фактура готова к отправке"
        }
    }

    private func sharedFooterText(for type: DocumentType) -> String {
        switch type {
        case .invoice:
            return "Ожидает оплаты"

        case .act:
            return "Документ отправлен клиенту"

        case .deliveryNote:
            return "Документ отправлен клиенту"
        }
    }
}
