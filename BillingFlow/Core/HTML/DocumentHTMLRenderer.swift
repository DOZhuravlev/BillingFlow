import Foundation

struct DocumentHTMLRenderer {

    func render(document: BusinessDocument) throws -> String {
        let template = try HTMLTemplateLoader.load(template(for: document.type))
        let context = DocumentTemplateContext(document: document)
        let replacements = makeReplacements(
            context: context,
            items: document.items,
            currencyCode: document.currencyCode
        )

        return apply(replacements: replacements, to: template)
    }

    private func template(for type: DocumentType) -> HTMLTemplateLoader.Template {
        switch type {
        case .invoice:
            return .invoice
        case .act:
            return .act
        case .deliveryNote:
            return .deliveryNote
        }
    }

    private func makeReplacements(
        context: DocumentTemplateContext,
        items: [DocumentItem],
        currencyCode: String
    ) -> [String: String] {
        [
            "documentTitle": context.documentTitle,
            "companyName": context.companyName,
            "companyDetails": context.companyDetails,
            "logoHiddenClass": "logo--hidden",
            "logoImage": "",
            "bankName": context.bankName,
            "bankRecipientLabel": context.bankRecipientLabel,
            "bankBIKLabel": context.bankBIKLabel,
            "bankBIK": context.bankBIK,
            "bankCorrespondentAccountLabel": context.bankCorrespondentAccountLabel,
            "bankCorrespondentAccount": context.bankCorrespondentAccount,
            "recipientLabel": context.recipientLabel,
            "companyINNLabel": context.companyINNLabel,
            "companyINN": context.companyINN,
            "companyKPPLabel": context.companyKPPLabel,
            "companyKPP": context.companyKPP,
            "companyAccountLabel": context.companyAccountLabel,
            "companyAccount": context.companyAccount,
            "invoiceNumber": context.invoiceNumber,
            "invoiceDate": context.invoiceDate,
            "supplierLabel": context.supplierLabel,
            "supplierDetails": context.supplierDetails,
            "buyerLabel": context.buyerLabel,
            "recipientDetails": context.recipientDetails,
            "basisLabel": context.basisLabel,
            "basisText": context.basisText,
            "basisRowHiddenClass": context.basisRowHiddenClass,
            "itemsTitleLabel": context.itemsTitleLabel,
            "quantityLabel": context.quantityLabel,
            "unitLabel": context.unitLabel,
            "priceLabel": context.priceLabel,
            "vatColumnLabel": context.vatColumnLabel,
            "sumLabel": context.sumLabel,
            "itemsVatColumnHiddenClass": context.itemsVATColumnHiddenClass,
            "itemsRows": renderItemRows(
                items,
                currencyCode: currencyCode,
                itemsVATCellHiddenClass: context.itemsVATCellHiddenClass
            ),
            "currencyRowHiddenClass": context.currencyRowHiddenClass,
            "currencyLabel": context.currencyLabel,
            "currencyCode": context.currencyCode,
            "currencySummaryText": context.currencySummaryText,
            "subtotalLabel": context.subtotalLabel,
            "subtotal": context.subtotalText,
            "vatRowHiddenClass": context.vatRowHiddenClass,
            "vatText": context.vatText,
            "vatAmount": context.vatAmountText,
            "totalLabel": context.totalLabel,
            "total": context.totalText,
            "summaryText": context.summaryText,
            "commentHiddenClass": context.commentHiddenClass,
            "comment": context.comment,
            "managerPosition": context.managerPosition,
            "managerName": context.managerName,
            "signImagesHiddenClass": "sign-images--hidden",
            "signatureHiddenClass": "signature--hidden",
            "signatureImage": "",
            "stampHiddenClass": "stamp--hidden",
            "stampImage": "",
            "footerNoteHiddenClass": "footer-note--hidden",
            "footerNote": ""
        ]
    }

    private func apply(
        replacements: [String: String],
        to template: String
    ) -> String {
        replacements.reduce(template) { partialHTML, replacement in
            partialHTML.replacingOccurrences(
                of: "{{\(replacement.key)}}",
                with: replacement.value
            )
        }
    }

    private func renderItemRows(
        _ items: [DocumentItem],
        currencyCode: String,
        itemsVATCellHiddenClass: String
    ) -> String {
        items.enumerated().map { index, item in
            let title = escape(item.title.isEmpty ? "Без названия" : item.title)
            let quantity = escape(formattedDecimal(item.quantity))
            let unit = escape(item.unit.isEmpty ? "шт" : item.unit)
            let price = escape(formattedAmount(item.price, currencyCode: currencyCode))
            let amount = escape(formattedAmount(item.amount, currencyCode: currencyCode))

            return """
            <tr>
              <td class="col-index">\(index + 1)</td>
              <td class="col-name">\(title)</td>
              <td class="col-qty">\(quantity)</td>
              <td class="col-unit">\(unit)</td>
              <td class="col-price">\(price)</td>
              <td class="col-vat \(itemsVATCellHiddenClass)"></td>
              <td class="col-sum">\(amount)</td>
            </tr>
            """
        }
        .joined(separator: "\n")
    }

    private func formattedAmount(_ value: Decimal, currencyCode: String) -> String {
        "\(formattedDecimal(value)) \(currencyCode)"
    }

    private func formattedDecimal(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        return Self.amountFormatter.string(from: number) ?? number.stringValue
    }

    private func escape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    static let amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.groupingSeparator = " "
        return formatter
    }()

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }()
}
