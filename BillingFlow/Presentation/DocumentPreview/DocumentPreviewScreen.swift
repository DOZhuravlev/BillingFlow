import SwiftUI
import UIKit

struct DocumentPreviewScreen: View {

    // MARK: - Properties

    let document: BusinessDocument

    @State private var isGeneratingPDF = false
    @State private var pdfURL: URL?
    @State private var runtimeErrorMessage: String?
    @State private var isShareSheetPresented = false

    private let pdfGenerator: PDFGenerator
    private let renderResult: Result<String, Error>

    // MARK: - Initialization

    init(
        document: BusinessDocument,
        htmlRenderer: DocumentHTMLRenderer = DocumentHTMLRenderer(),
        pdfGenerator: PDFGenerator = PDFGenerator()
    ) {
        self.document = document
        self.pdfGenerator = pdfGenerator
        self.renderResult = Result {
            try htmlRenderer.render(document: document)
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            paperPreviewBlock
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 8) {
                summaryBlock
                signatureRow
                sendInvoiceButton
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .sheet(isPresented: $isShareSheetPresented) {
            if let pdfURL {
                ShareSheet(activityItems: [pdfURL])
            }
        }
        .navigationTitle("Предпросмотр")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Content

    private var paperPreviewBlock: some View {
        DocumentPreviewWebView(html: renderedHTML)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.10), radius: 16, x: 0, y: 6)
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.secondarySystemBackground))
    }

    private var summaryBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 1) {
                Text(amountText(document.totals.total))
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("НДС не применяется")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(buyerDisplayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                if document.buyer.taxID.isEmpty == false {
                    Text("ИНН: \(document.buyer.taxID)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(summaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.035), radius: 10, x: 0, y: 6)
    }

    private var signatureRow: some View {
        Button {
            // TODO: Implement signature/stamp flow
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "signature")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.blue)
                    .frame(width: 36, height: 36)
                    .background(Color.blue.opacity(0.09))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text("Подпись и печать")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.white.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.black.opacity(0.04), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var sendInvoiceButton: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let visibleErrorMessage, visibleErrorMessage.isEmpty == false {
                Text(visibleErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button {
                Task {
                    await sharePDF()
                }
            } label: {
                HStack(spacing: 12) {
                    if isGeneratingPDF {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                    }

                    Text(isGeneratingPDF ? "Готовим PDF..." : "Отправить счет")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(isGeneratingPDF || hasInitialRenderError)
        }
    }

    // MARK: - Actions

    private func sharePDF() async {
        guard isGeneratingPDF == false else { return }
        guard hasInitialRenderError == false else { return }

        runtimeErrorMessage = nil
        isGeneratingPDF = true
        defer { isGeneratingPDF = false }

        do {
            let url = try await pdfGenerator.generatePDF(for: document)
            pdfURL = url
            isShareSheetPresented = true
        } catch {
            runtimeErrorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private var renderedHTML: String {
        switch renderResult {
        case .success(let html):
            return html
        case .failure:
            return fallbackHTML
        }
    }

    private var initialRenderErrorMessage: String? {
        guard case .failure(let error) = renderResult else { return nil }
        return error.localizedDescription
    }

    private var visibleErrorMessage: String? {
        runtimeErrorMessage ?? initialRenderErrorMessage
    }

    private var hasInitialRenderError: Bool {
        if case .failure = renderResult {
            return true
        }
        return false
    }

    private var buyerDisplayName: String {
        document.buyer.displayName.isEmpty ? "Покупатель не указан" : document.buyer.displayName
    }

    private var summaryBackground: Color {
        Color(uiColor: UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1))
    }

    private func amountText(_ amount: Decimal) -> String {
        let number = NSDecimalNumber(decimal: amount)
        let formatted = Self.amountFormatter.string(from: number) ?? number.stringValue
        return "\(formatted) \(document.currencyCode)"
    }

    private static let amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.groupingSeparator = " "
        return formatter
    }()

    private var fallbackHTML: String {
        """
        <!DOCTYPE html>
        <html lang="ru">
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    margin: 0;
                    padding: 0;
                    background: #ffffff;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    color: #1c1c1e;
                }

                .container {
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    justify-content: center;
                    height: 100vh;
                    padding: 24px;
                    box-sizing: border-box;
                    text-align: center;
                }

                .icon {
                    font-size: 40px;
                    margin-bottom: 16px;
                    opacity: 0.6;
                }

                .title {
                    font-size: 17px;
                    font-weight: 600;
                    margin-bottom: 6px;
                }

                .subtitle {
                    font-size: 13px;
                    color: #8e8e93;
                    line-height: 1.4;
                    max-width: 260px;
                }

                .card {
                    margin-top: 32px;
                    width: 100%;
                    max-width: 320px;
                    border-radius: 16px;
                    background: #f2f2f7;
                    padding: 16px;
                    font-size: 12px;
                    color: #6e6e73;
                }
            </style>
        </head>

        <body>
            <div class="container">
                <div class="icon">📄</div>

                <div class="title">
                    Не удалось отобразить документ
                </div>

                <div class="subtitle">
                    Попробуйте обновить данные или проверить корректность заполнения
                </div>

                <div class="card">
                    Ошибка: \(initialRenderErrorMessage ?? "неизвестная ошибка")
                </div>
            </div>
        </body>
        </html>
        """
    }
}

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DocumentPreviewScreen(
            document: BusinessDocument(
                type: .invoice,
                number: "INV-2026-001",
                date: Date(),
                seller: DocumentParty(
                    displayName: "ООО BillingFlow Studio",
                    taxID: "6678123456",
                    registrationNumber: "667801001",
                    address: "г. Москва, ул. Горького, 12",
                    bankName: "АО Т-Банк",
                    bankAccount: "40702810900000000001",
                    bankCode: "044525974",
                    contactName: "Иван Иванов",
                    phone: "+7 912 000-00-00",
                    email: "finance@billingflow.app"
                ),
                buyer: DocumentParty(
                    displayName: "ООО Альфа",
                    taxID: "7701234567",
                    address: "г. Москва, ул. Тверская, 8",
                    phone: "+7 999 123-45-67",
                    email: "pay@alfa.ru"
                ),
                items: [
                    DocumentItem(
                        title: "Разработка интерфейса",
                        quantity: 1,
                        unit: "услуга",
                        price: 45_000
                    ),
                    DocumentItem(
                        title: "Подготовка PDF-документа",
                        quantity: 2,
                        unit: "час",
                        price: 3_500
                    )
                ],
                notes: "Оплата в течение 5 рабочих дней.",
                currencyCode: "RUB",
                status: .ready
            )
        )
    }
}
