import Foundation

struct DocumentTemplateContext {

    // MARK: - Properties

    let documentTitle: String
    let companyName: String
    let companyDetails: String
    let bankName: String
    let bankRecipientLabel: String
    let bankBIKLabel: String
    let bankBIK: String
    let bankCorrespondentAccountLabel: String
    let bankCorrespondentAccount: String
    let recipientLabel: String
    let companyINNLabel: String
    let companyINN: String
    let companyKPPLabel: String
    let companyKPP: String
    let companyAccountLabel: String
    let companyAccount: String
    let invoiceNumber: String
    let invoiceDate: String
    let supplierLabel: String
    let supplierDetails: String
    let buyerLabel: String
    let recipientDetails: String
    let basisLabel: String
    let basisText: String
    let basisRowHiddenClass: String
    let itemsTitleLabel: String
    let quantityLabel: String
    let unitLabel: String
    let priceLabel: String
    let vatColumnLabel: String
    let sumLabel: String
    let itemsVATColumnHiddenClass: String
    let itemsVATCellHiddenClass: String
    let currencyRowHiddenClass: String
    let currencyLabel: String
    let currencyCode: String
    let currencySummaryText: String
    let subtotalLabel: String
    let subtotalText: String
    let vatRowHiddenClass: String
    let vatText: String
    let vatAmountText: String
    let totalLabel: String
    let totalText: String
    let summaryText: String
    let commentHiddenClass: String
    let comment: String
    let managerPosition: String
    let managerName: String

    // MARK: - Initialization

    init(document: BusinessDocument) {
        let totals = document.totals
        let numberFormatter = DocumentHTMLRenderer.amountFormatter
        let totalNumber = NSDecimalNumber(decimal: totals.total)
        let subtotalNumber = NSDecimalNumber(decimal: totals.subtotal)
        let formattedTotal = numberFormatter.string(from: totalNumber) ?? totalNumber.stringValue
        let formattedSubtotal = numberFormatter.string(from: subtotalNumber) ?? subtotalNumber.stringValue

        self.documentTitle = Self.title(for: document.type)
        self.companyName = Self.raw(document.seller.displayName, fallback: "Компания не указана")
        self.companyDetails = Self.lines([
            document.seller.address,
            document.seller.phone,
            document.seller.email
        ])
        self.bankName = Self.raw(document.seller.bankName, fallback: "Банк не указан")
        self.bankRecipientLabel = "Банк получателя"
        self.bankBIKLabel = "БИК"
        self.bankBIK = Self.raw(document.seller.bankCode, fallback: "—")
        self.bankCorrespondentAccountLabel = "Корр. счёт"
        self.bankCorrespondentAccount = "—"
        self.recipientLabel = "Получатель"
        self.companyINNLabel = "ИНН"
        self.companyINN = Self.raw(document.seller.taxID, fallback: "—")
        self.companyKPPLabel = "КПП"
        self.companyKPP = Self.raw(document.seller.registrationNumber, fallback: "—")
        self.companyAccountLabel = "Сч. №"
        self.companyAccount = Self.raw(document.seller.bankAccount, fallback: "—")
        self.invoiceNumber = Self.raw(document.number, fallback: "Без номера")
        self.invoiceDate = DocumentHTMLRenderer.dateFormatter.string(from: document.date)
        self.supplierLabel = Self.supplierLabel(for: document.type)
        self.supplierDetails = Self.lines([
            document.seller.displayName,
            document.seller.taxID.isEmpty ? "" : "ИНН \(document.seller.taxID)",
            document.seller.address
        ])
        self.buyerLabel = Self.buyerLabel(for: document.type)
        self.recipientDetails = Self.lines([
            document.buyer.displayName,
            document.buyer.taxID.isEmpty ? "" : "ИНН \(document.buyer.taxID)",
            document.buyer.address
        ])
        self.basisLabel = "Основание"
        self.basisText = ""
        self.basisRowHiddenClass = "basis-row--hidden"
        self.itemsTitleLabel = Self.itemsTitleLabel(for: document.type)
        self.quantityLabel = "Кол-во"
        self.unitLabel = "Ед."
        self.priceLabel = "Цена"
        self.vatColumnLabel = "НДС"
        self.sumLabel = "Сумма"
        self.itemsVATColumnHiddenClass = "items-vat-column--hidden"
        self.itemsVATCellHiddenClass = "items-vat-cell--hidden"
        self.currencyRowHiddenClass = document.currencyCode.isEmpty ? "currency-row--hidden" : ""
        self.currencyLabel = "Валюта"
        self.currencyCode = Self.raw(document.currencyCode, fallback: "RUB")
        self.currencySummaryText = document.currencyCode.isEmpty ? "" : "Все суммы указаны в \(document.currencyCode)"
        self.subtotalLabel = "Подытог"
        self.subtotalText = "\(formattedSubtotal) \(document.currencyCode)"
        self.vatRowHiddenClass = "vat-row--hidden"
        self.vatText = "НДС"
        self.vatAmountText = ""
        self.totalLabel = "Итого"
        self.totalText = "\(formattedTotal) \(document.currencyCode)"
        self.summaryText = "Всего наименований \(totals.itemCount), на сумму \(formattedTotal) \(document.currencyCode)"
        self.commentHiddenClass = document.notes.isEmpty ? "comment--hidden" : ""
        self.comment = document.notes
        self.managerPosition = "Руководитель"
        self.managerName = Self.raw(document.seller.contactName, fallback: companyName)
    }

    // MARK: - Private Helpers

    private static func title(for type: DocumentType) -> String {
        switch type {
        case .invoice:
            return "Счет на оплату"
        case .act:
            return "Акт"
        case .deliveryNote:
            return "Накладная"
        }
    }

    private static func supplierLabel(for type: DocumentType) -> String {
        switch type {
        case .invoice, .deliveryNote:
            return "Поставщик"
        case .act:
            return "Исполнитель"
        }
    }

    private static func buyerLabel(for type: DocumentType) -> String {
        switch type {
        case .invoice:
            return "Покупатель"
        case .act:
            return "Заказчик"
        case .deliveryNote:
            return "Получатель"
        }
    }

    private static func itemsTitleLabel(for type: DocumentType) -> String {
        switch type {
        case .invoice:
            return "Товары (работы, услуги)"
        case .act:
            return "Работы (услуги)"
        case .deliveryNote:
            return "Товары"
        }
    }

    private static func raw(_ value: String, fallback: String) -> String {
        value.isEmpty ? fallback : value
    }

    private static func lines(_ parts: [String]) -> String {
        parts
            .filter { $0.isEmpty == false }
            .joined(separator: "\n")
    }
}
